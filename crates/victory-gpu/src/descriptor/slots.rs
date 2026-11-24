//! Next-fit allocation for contiguous dynamic descriptor slots.

/// Search candidate starts from the cursor, then from slot zero. A table
/// may span the cursor, but all its slots must fit before the heap end.
pub(super) fn find_free(taken: &[bool], cursor: usize, count: usize) -> Option<usize> {
    if count == 0 || count > taken.len() {
        return None;
    }
    let first_run = |slots: &[bool]| {
        let mut free = 0;
        slots.iter().position(|&used| {
            free = if used { 0 } else { free + 1 };
            free == count
        })
    };
    if let Some(end) = first_run(&taken[cursor..]) {
        return Some(cursor + end + 1 - count);
    }
    // The last candidate before the cursor may extend count - 1 slots
    // into the suffix we already searched.
    let limit = cursor.saturating_add(count - 1).min(taken.len());
    first_run(&taken[..limit]).map(|end| end + 1 - count)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn free_range_spans_search_cursor() {
        assert_eq!(find_free(&[true, false, false, false, true], 3, 3), Some(1));
        assert_eq!(find_free(&[false, true, true, false], 3, 2), None);
    }

    #[test]
    fn empty_tables_and_empty_heaps_have_no_allocation() {
        assert_eq!(find_free(&[false], 0, 0), None);
        assert_eq!(find_free(&[], 0, 1), None);
    }

    #[test]
    fn next_fit_matches_all_candidate_starts() {
        for len in 1..=8 {
            for mask in 0..1usize << len {
                let taken: Vec<_> = (0..len).map(|slot| mask & (1 << slot) != 0).collect();
                for cursor in 0..len {
                    for count in 1..=len + 1 {
                        let expected = (cursor..len).chain(0..cursor).find(|&start| {
                            taken
                                .get(start..start + count)
                                .is_some_and(|range| !range.contains(&true))
                        });
                        assert_eq!(find_free(&taken, cursor, count), expected);
                    }
                }
            }
        }
    }
}
