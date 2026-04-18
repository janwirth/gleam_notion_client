import gleeunit
import notion_client/error.{
  ApiResponseError, ObjectNotFound, UnknownErrorCode, ValidationError,
}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_api_error_object_not_found_test() {
  let body = <<
    "{\"object\":\"error\",\"status\":404,\"code\":\"object_not_found\",\"message\":\"Could not find block.\"}":utf8,
  >>
  assert error.parse_api_error(body, 404)
    == ApiResponseError(ObjectNotFound, 404, "Could not find block.")
}

pub fn parse_api_error_validation_test() {
  let body = <<
    "{\"object\":\"error\",\"code\":\"validation_error\",\"message\":\"body failed validation\"}":utf8,
  >>
  assert error.parse_api_error(body, 400)
    == ApiResponseError(ValidationError, 400, "body failed validation")
}

pub fn parse_api_error_unknown_code_test() {
  let body = <<
    "{\"object\":\"error\",\"code\":\"some_future_code\",\"message\":\"new code\"}":utf8,
  >>
  assert error.parse_api_error(body, 418)
    == ApiResponseError(UnknownErrorCode("some_future_code"), 418, "new code")
}

pub fn parse_api_error_garbage_body_test() {
  let body = <<"not json at all":utf8>>
  assert error.parse_api_error(body, 502)
    == ApiResponseError(
      UnknownErrorCode("decode_failed"),
      502,
      "not json at all",
    )
}
