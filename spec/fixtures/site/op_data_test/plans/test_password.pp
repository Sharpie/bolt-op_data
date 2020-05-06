plan op_data_test::test_password (
) {
  $_target = get_target('localhost')
  $_var = $_target.vars['test_password']
  $_expectation = 'correct horse battery staple'

  if $_var == $_expectation {
    out::message('test passed')
  } else {
    fail("Result ${_var} did not match expectation ${_expectation}")
  }
}
