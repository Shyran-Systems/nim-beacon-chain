mode = ScriptMode.Verbose

import
  beacon_chain/version as ver

packageName   = "beacon_chain"
version       = versionAsStr
author        = "Status Research & Development GmbH"
description   = "Eth2.0 research implementation of the beacon chain"
license       = "MIT or Apache License 2.0"
installDirs   = @["beacon_chain", "research"]
skipDirs      = @["nfuzz"]
bin           = @[
  "beacon_chain/beacon_node",
  "research/serialized_sizes",
  "nbench/nbench",
  ]

### Dependencies
requires "nim >= 0.19.0",
  "blscurve",
  "chronicles",
  "chronos",
  "confutils",
  "eth",
  "json_rpc",
  "json_serialization",
  "libbacktrace",
  "libp2p",
  "metrics",
  "nimcrypto",
  "serialization",
  "stew",
  "testutils",
  "prompt",
  "web3",
  "yaml"

### Helper functions
proc buildBinary(name: string, srcDir = "./", params = "", cmdParams = "", lang = "c") =
  if not dirExists "build":
    mkDir "build"
  # allow something like "nim test --verbosity:0 --hints:off beacon_chain.nims"
  var extra_params = params
  for i in 2..<paramCount():
    extra_params &= " " & paramStr(i)
  exec "nim " & lang & " --out:./build/" & name & " -r " & extra_params & " " & srcDir & name & ".nim" & " " & cmdParams

task moduleTests, "Run all module tests":
  buildBinary "beacon_node", "beacon_chain/",
              "-d:chronicles_log_level=TRACE " &
              "-d:const_preset=minimal " &
              "-d:testutils_test_build"

### tasks
task test, "Run all tests":
  # We're enabling the TRACE log level so we're sure that those rarely used
  # pieces of code get tested regularly. Increased test output verbosity is the
  # price we pay for that.

  # Minimal config
  buildBinary "proto_array", "beacon_chain/fork_choice/", "-d:const_preset=minimal"
  buildBinary "fork_choice", "beacon_chain/fork_choice/", "-d:const_preset=minimal"
  buildBinary "all_tests", "tests/", "-d:chronicles_log_level=TRACE -d:const_preset=minimal"
  # Mainnet config
  buildBinary "proto_array", "beacon_chain/fork_choice/", "-d:const_preset=mainnet"
  buildBinary "fork_choice", "beacon_chain/fork_choice/", "-d:const_preset=mainnet"
  buildBinary "all_tests", "tests/", "-d:const_preset=mainnet"

  # Generic SSZ test, doesn't use consensus objects minimal/mainnet presets
  buildBinary "test_fixture_ssz_generic_types", "tests/official/", "-d:chronicles_log_level=TRACE"

  # Consensus object SSZ tests
  buildBinary "test_fixture_ssz_consensus_objects", "tests/official/", "-d:chronicles_log_level=TRACE -d:const_preset=minimal"
  buildBinary "test_fixture_ssz_consensus_objects", "tests/official/", "-d:const_preset=mainnet"

  buildBinary "all_fixtures_require_ssz", "tests/official/", "-d:chronicles_log_level=TRACE -d:const_preset=minimal"
  buildBinary "all_fixtures_require_ssz", "tests/official/", "-d:const_preset=mainnet"

  # State sim; getting into 4th epoch useful to trigger consensus checks
  buildBinary "state_sim", "research/", "-d:const_preset=minimal", "--validators=2000 --slots=32"
  buildBinary "state_sim", "research/", "-d:const_preset=mainnet", "--validators=2000 --slots=128"
