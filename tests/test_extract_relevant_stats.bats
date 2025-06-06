#!/usr/bin/env bats

setup() {
  tmpdir="$BATS_TMPDIR/work"
  mkdir -p "$tmpdir"
  cd "$tmpdir"
  cp "$BATS_TEST_DIRNAME/data/example.flagstat.txt" .
}

@test "extract_relevant_stats parses flagstat" {
  run bash "$BATS_TEST_DIRNAME/../Modules/02_alignment/extract_relevant_stats"
  [ "$status" -eq 0 ]

  expected_header=$'sample_name\ttotal_reads\tpercent_mapped\tpercent_properly_paired\tpercent_singletons'
  [ "${lines[0]}" = "$expected_header" ]

  [ "${lines[1]}" = $'example\t4\t100.00\t100.00\t0.00' ]
}
