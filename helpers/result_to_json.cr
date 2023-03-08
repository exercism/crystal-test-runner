require "json"
require "xml"

spec_output = ARGV[0]?
junit_file = ARGV[1]?
scaffold_json = ARGV[2]?
output_file = ARGV[3]?

PASS  = "pass"
FAIL  = "fail"
ERROR = "error"

TAG_TESTSUITE = "testsuite"
TAG_TESTCASE  = "testcase"
TAG_FAILURE   = "failure"
TAG_ERROR     = "error"
TAG_SKIPPED   = "skipped"

ATTR_MESSAGE = "message"
ATTR_NAME    = "name"

class TestCase
  include JSON::Serializable

  getter name : String
  getter test_code : String?
  property status : String?
  property message : String?
  property output : String?
  property task_id : Int32?

  def initialize(@name, @test_code, @status, @message, @output, @task_id = nil)
  end
end

class TestRun
  include JSON::Serializable

  getter version : Int32
  property status : String?
  property message : String?
  property tests : Array(TestCase)
end

def find_element(node : XML::Node, name : String)
  node.children.find do |child|
    child.name == name
  end
end

def find_testsuite(document : XML::Node)
  find_element(document, TAG_TESTSUITE).not_nil!
end

def convert_to_test_cases(test_suite : XML::Node, json_file : JSON::Any)
  i = -1
  test_suite.children
    .map do |test_case|
      if test_case.name != TAG_TESTCASE
        next nil
      end

      error = find_element(test_case, TAG_ERROR)
      failure = find_element(test_case, TAG_FAILURE)
      skipped = find_element(test_case, TAG_SKIPPED)

      status =
        case
        when error   then ERROR
        when failure then FAIL
        when skipped then ERROR
        else              PASS
        end

      message =
        case
        when error   then "#{error[ATTR_MESSAGE]}\n#{test_case.content}".strip
        when failure then failure[ATTR_MESSAGE].strip
        when skipped then "Test case unexpectedly skipped"
        else              nil
        end
      i += 1
      output = json_file[i].to_s.empty? ? nil : json_file[i].to_s
      TestCase.new(
        test_case[ATTR_NAME],
        nil,
        status,
        message,
        output,
        test_case["task_id"]? ? test_case["task_id"].to_i : nil
      )
    end
    .compact
end

def merge_test_cases(a : Array(TestCase), b : Array(TestCase))
  a.zip(b).map do |a, b|
    a.status = b.status
    a.message = b.message
    a.output = b.output
    a
  end
end

def set_test_run_status(test_run : TestRun, document : XML::Node)
  testcase_count = document["tests"].not_nil!.to_i
  skipped_count = document["skipped"].not_nil!.to_i
  errors_count = document["errors"].not_nil!.to_i
  failures_count = document["failures"].not_nil!.to_i

  status = (testcase_count - skipped_count - failures_count - errors_count) == testcase_count ? PASS : FAIL

  test_run.status = status
end

def set_test_run_error(test_run : TestRun, spec_output : String?)
  test_run.status = ERROR
  test_run.message = spec_output
  test_run.tests.each do |test_case|
    test_case.status = FAIL
  end
end

#
# Main start
#

unless spec_output && junit_file && scaffold_json && output_file
  puts <<-USAGE
    Usage:
    > result_to_json <captured spec> <junit xml> <scaffold json> <output file>
    USAGE
  exit 1
end

puts "* Reading scaffold json 📖"

test_run = TestRun.from_json(File.read(scaffold_json))

puts "* Checking if junit xml exists 🔍"

if !File.exists?(junit_file)
  puts "* Failed finding junit xml ❌"

  set_test_run_error(test_run, File.read(spec_output))

  puts "* Writing error result json to: #{output_file} 🖊"

  File.write(output_file, test_run.to_json)
  exit
end

puts "* Reading junit xml ✅"

junit_xml = File.read(junit_file)
junit_document = XML.parse(junit_xml)
junit_testsuite = find_testsuite(junit_document)

json_ouput = JSON.parse(File.read("/tmp/ouput.json"))
File.delete("/tmp/ouput.json")

test_cases = convert_to_test_cases(junit_testsuite, json_ouput)
test_run.tests = merge_test_cases(test_run.tests, test_cases)
set_test_run_status(test_run, junit_testsuite)

puts "* Writing merged result json to: #{output_file} 🖊"

File.write(output_file, test_run.to_json)

puts "* All done! 🏁"
