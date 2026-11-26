//! Immutable dependencies of the closed lists in one submission. Steps that
//! execute work still run in recording order, including repeated lists.
use super::{Declared, HostList, Step};
use crate::shadow::Shadow;
use std::collections::{HashMap, HashSet};
use std::sync::{Arc, OnceLock};

#[cfg(feature = "diagnostics")]
pub(super) static BUILD_US: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

pub(super) fn mode() -> u8 {
    static MODE: OnceLock<u8> = OnceLock::new();
    *MODE.get_or_init(
        || match std::env::var("VICTORY_SUBMISSION_INDEX").as_deref() {
            Ok("1") => 1,
            Ok("verify") => 2,
            _ => 0,
        },
    )
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(super) enum Hazard {
    Copy(usize, usize, usize),
    Fill(usize, usize),
    Texture(usize, usize),
    Run,
}

impl Hazard {
    pub(super) fn from_step(step: &Step) -> Option<Self> {
        match step {
            &Step::Copy(dst, src, len) => Some(Self::Copy(dst, src, len)),
            &Step::Fill(_, src, len) => Some(Self::Fill(src, len)),
            Step::Texture(staging) => {
                let (at, len) = staging.memory();
                Some(Self::Texture(at, len))
            }
            Step::Run(_) => Some(Self::Run),
            Step::Host(_) | Step::Refresh(..) | Step::GpuWrite(..) => None,
        }
    }
}

#[derive(Default)]
pub(super) struct SubmissionIndex {
    pub(super) writes: Vec<Declared>,
    pub(super) refresh: Vec<(Arc<Shadow>, usize, usize)>,
    pub(super) hazards: Vec<Hazard>,
}

impl SubmissionIndex {
    pub(super) fn collect(runs: &[&HostList]) -> Self {
        #[cfg(feature = "diagnostics")]
        let started = std::time::Instant::now();
        let mut index = Self::default();
        let mut write_positions = HashMap::new();
        let mut seen = HashSet::new();
        let mut refresh_positions = HashMap::new();
        for list in runs {
            for step in &list.deferred().copies {
                match step {
                    Step::GpuWrite(shadow, at, len) => {
                        let key = Arc::as_ptr(shadow);
                        let range = (*at, *at + *len);
                        if seen.insert((key, range)) {
                            let pos = *write_positions.entry(key).or_insert_with(|| {
                                index.writes.push((shadow.clone(), Vec::new()));
                                index.writes.len() - 1
                            });
                            index.writes[pos].1.push(range);
                        }
                    }
                    Step::Refresh(shadow, at, len) => {
                        let pos =
                            *refresh_positions
                                .entry(Arc::as_ptr(shadow))
                                .or_insert_with(|| {
                                    index.refresh.push((shadow.clone(), *at, *at + *len));
                                    index.refresh.len() - 1
                                });
                        let span = &mut index.refresh[pos];
                        span.1 = span.1.min(*at);
                        span.2 = span.2.max(*at + *len);
                    }
                    other => index.hazards.extend(Hazard::from_step(other)),
                }
            }
        }
        #[cfg(feature = "diagnostics")]
        BUILD_US.fetch_add(
            started.elapsed().as_micros() as u64,
            std::sync::atomic::Ordering::Relaxed,
        );
        index
    }

    /// Compare against a separate traversal before using the index. A
    /// disagreement falls back to the original scans for this submission.
    pub(super) fn agrees(&self, runs: &[&HostList]) -> bool {
        let old = super::declared_writes(runs);
        if self.writes.len() != old.len()
            || !self
                .writes
                .iter()
                .zip(old)
                .all(|((a, x), (b, y))| Arc::ptr_eq(a, &b) && *x == y)
        {
            return false;
        }
        let mut spans = HashMap::new();
        let mut hazards = self.hazards.iter();
        for list in runs {
            for step in &list.deferred().copies {
                if let Step::Refresh(shadow, at, len) = step {
                    let span = spans
                        .entry(Arc::as_ptr(shadow))
                        .or_insert((*at, *at + *len));
                    span.0 = span.0.min(*at);
                    span.1 = span.1.max(*at + *len);
                } else if let Some(access) = Hazard::from_step(step) {
                    if hazards.next() != Some(&access) {
                        return false;
                    }
                }
            }
        }
        hazards.next().is_none()
            && spans.len() == self.refresh.len()
            && self
                .refresh
                .iter()
                .all(|(s, a, b)| spans.get(&Arc::as_ptr(s)) == Some(&(*a, *b)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn repeated_lists_keep_ordered_hazards_and_deduplicate_shader_ranges() {
        let Some(host) = super::super::host() else {
            return;
        };
        let bytes = vec![0u8; 4096];
        let start = bytes.as_ptr() as usize;
        crate::shadow::register(start, start as u64, bytes.len() as u64);
        let shadow = crate::shadow::find(start as u64, bytes.len() as u64).unwrap();
        let list = host.new_list().unwrap();
        list.deferred().copies.extend([
            Step::Refresh(shadow.clone(), start + 16, 48),
            Step::GpuWrite(shadow.clone(), start + 32, 64),
            Step::Copy(start + 32, start + 96, 8),
            Step::Run(Box::new(|| {})),
            Step::Refresh(shadow.clone(), start, 32),
            Step::GpuWrite(shadow.clone(), start, 64),
        ]);
        list.close();
        let runs = [&list, &list];
        let mut index = SubmissionIndex::collect(&runs);
        assert!(index.agrees(&runs));
        assert_eq!(
            index.writes[0].1,
            [(start + 32, start + 96), (start, start + 64)]
        );
        assert_eq!(
            (index.refresh[0].1, index.refresh[0].2),
            (start, start + 64)
        );
        assert_eq!(index.hazards.len(), 4);
        for (at, why) in [
            (start + 32, super::super::WHY_READ),
            (start + 72, super::super::WHY_RUN),
        ] {
            let written = [(at, at + 1)];
            for summary in [None, Some(&index)] {
                assert_eq!(
                    super::super::blocked_by(&written, &runs, summary, false),
                    Some(why)
                );
            }
        }
        index.hazards.pop();
        assert!(!index.agrees(&runs));
        crate::shadow::unregister(start, start as u64);
    }
}
