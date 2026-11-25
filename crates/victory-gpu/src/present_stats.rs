//! Five-second windows of intervals between successful host swap-chain presents.

use std::time::{Duration, Instant};

#[derive(Default)]
pub(crate) struct Window {
    first: Option<(Instant, u64)>,
    previous: Option<Instant>,
    intervals: Vec<Duration>,
    skipped: u64,
}

pub(crate) struct Reading {
    pub frames: usize,
    pub elapsed: Duration,
    pub draws: u64,
    pub p95: Duration,
    pub worst: Duration,
    pub skipped: u64,
}

impl Window {
    pub fn observe(&mut self, now: Instant, shown: bool, draws: u64) -> Option<Reading> {
        if !shown {
            self.skipped += 1;
            return None;
        }
        let (start, first_draws) = *self.first.get_or_insert((now, draws));
        let previous = self.previous.replace(now)?;
        self.intervals.push(now.duration_since(previous));
        let elapsed = now.duration_since(start);
        if elapsed < Duration::from_secs(5) {
            return None;
        }
        let frames = self.intervals.len();
        self.intervals.sort_unstable();
        let result = Reading {
            frames,
            elapsed,
            draws: draws.saturating_sub(first_draws),
            p95: self.intervals[(frames * 95).div_ceil(100) - 1],
            worst: self.intervals[frames - 1],
            skipped: std::mem::take(&mut self.skipped),
        };
        self.intervals.clear();
        self.first = Some((now, draws));
        Some(result)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn windows_count_shown_intervals_and_keep_real_stalls() {
        let start = Instant::now();
        let mut window = Window::default();
        for i in 0..20 {
            assert!(window.observe(start + Duration::from_millis(i * 200), true, i * 10).is_none());
        }
        assert!(window.observe(start + Duration::from_secs(4), false, 195).is_none());
        let sample = window.observe(start + Duration::from_secs(5), true, 200).unwrap();
        assert_eq!((sample.frames, sample.draws, sample.skipped), (20, 200, 1));
        assert_eq!(sample.elapsed, Duration::from_secs(5));
        assert_eq!(sample.p95, Duration::from_millis(200));
        assert_eq!(sample.worst, Duration::from_millis(1200));
        let next = window.observe(start + Duration::from_secs(11), true, 260).unwrap();
        assert_eq!((next.frames, next.draws, next.skipped), (1, 60, 0));
        assert_eq!(next.p95, Duration::from_secs(6));
    }
}
