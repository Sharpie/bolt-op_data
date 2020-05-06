plan op_data_test::test_login (
) {
  $_target = get_target('localhost')
  $_var = $_target.vars['test_login']
  $_expectation = Struct[{'user' => Pattern[/AzureDiamond/],
                          'pass' => Pattern[/hunter2/]}]

  if $_var =~ $_expectation {
    out::message('test passed')
  } else {
    fail("Result ${_var} did not match expectation ${_expectation}")
  }
}
