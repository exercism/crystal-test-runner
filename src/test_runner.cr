require "compiler/crystal/syntax"
require "json"
require "./test_visitor.cr"
require "xml"

module TestRunner

  # The TestCase class is used to represent a single test case,
  # following the version 3 of the exercisms test runner interface.
  #
  # The class is [json serializable](https://crystal-lang.org/api/JSON/Serializable.html), and can thereby have methods
  # to modify the state of the object.
  # The class does not feature any other methods then json serialization.
  class TestCase
    include JSON::Serializable
    property name : String
    property status : String
    property test_code : String
    property message : String?
    property output : String?
    property task_id : Int32?

    # Initializes a new TestCase object.
    #
    # The class takes the following arguments when initialized:
    # - *name* - The name of the test case
    # - *status* - The status of the test case, can be either "pass", "fail" or "error"
    # - *test_code* - The code that was tested
    # - *message* - The error message if the test case failed or errored
    # - *output* - The output of the test case
    # - *task_id* - The id of the task that the test case belongs to
    #
    # Example:
    # ```
    # TestCase.new("test case name", "pass", "test code", nil, "test output", 1)
    # ```
    def initialize(name : String, status : String, test_code : String, message : String?, output : String?, task_id : Int32?)
      @name = name
      @status = status
      @test_code = test_code
      @message = message
      @output = output
      @task_id = task_id
    end
  end

  # The TestSuite class is used to represent a test suite,
  # following the version 3 of the exercisms test runner interface.
  #
  # The class is [json serializable](https://crystal-lang.org/api/JSON/Serializable.html), and can thereby have methods
  # to modify the state of the object.
  # The class does not feature any other methods then json serialization.
  class TestSuite
    include JSON::Serializable
    property version : Int32 = 3 # The version of the test runner interface
    property status : String
    property message : String?
    property tests : Array(TestCase)?

    # Initializes a new TestSuite object.
    #
    # The class takes the following arguments when initialized:
    # - *status* - The status of the test suite, can be either "pass", "fail" or "error"
    # - *message* - The error message if the test suite failed or errored
    # - *tests* - The tests that the test suite contains
    # 
    # Example:
    # ```
    # TestSuite.new("pass", nil, [TestCase.new("test case name", "pass", "test code", nil, "test output", 1)])
    # ```
    def initialize(status : String, message : String?, tests : Array(TestCase)?)
      @status = status
      @tests = tests
      @message = message
    end
  end

  # The execute method is the entry point of the test runner
  # and is used to execute the test runner and write the result file.
  #
  # The method takes the following arguments:
  # - *spec_file* - The path to the spec file
  # - *capture_file* - The path to the capture file
  # - *junit_file* - The path to the junit xml file
  # - *result_file* - The path to the result file
  #
  # Example:
  # ```
  # TestRunner.execute("/tmp/spec.cr", "/tmp/capture.txt", "/tmp/junit.xml", "/tmp/result.json")
  # ```
  def self.execute(spec_file_path : String, capture_file_path : String, junit_file_path : String, result_file_path : String)
    included_failing = false # This determines if the test suite should be marked as passing or failing

    # If the junit xml file does not exist, then it is assumed that the test suite errored.
    # The error message is read from the capture file and written to the result file and
    # execution is stopped.
    unless File.exists?(junit_file_path)
      puts "* Failed finding junit xml ❌"
      error_message = File.read(capture_file_path)
      File.write(result_file_path, TestSuite.new("error", error_message, nil).to_json)
      exit(0)
    end

    # If the junit xml file exists it is parsed using the parse_xml method.
    junit_testsuite = parse_xml(junit_file_path)
    puts "* Reading junit xml ✅"

    parsed_spec_file = parse_spec_file(spec_file_path)
    puts "* Reading spec file ✅"

    # The standard output has a set path defined by the **setup_test_file.cr** file.
    parsed_standard_output = parse_standard_output
    puts "* Parsing standard output ✅"
  
    # Assinging the testcases through looping through the ast of the spec file.
    test_cases = parsed_spec_file.map_with_index do |snippet, index|

      # Finding the test case in the junit xml file that matches the current test case.
      # This expression returns the test case node if it is found, otherwise it returns nil.
      test_case = junit_testsuite.children.find do |test_case|
        name = test_case["name"]?
        # if the name is nil, then it is assumed that the xml node is not a test case node.
        if name.nil?
          false
        else
          name == snippet[:name]
        end
      end

      # If the test case isnt found then it is taken for granted that an error occured during exection.
      if test_case
        # If the standard output is empty, then the output is set to nil.
        if parsed_standard_output[index].to_s.empty?
          output = nil
        else
          output = parsed_standard_output[index].to_s
        end

        # Checking if there is a subnode called failure.
        failure = test_case.children.find { |node| node.name == "failure" }

        if failure.nil?
          TestCase.new(snippet[:name], "pass", snippet[:snippet], nil, output, snippet[:task_id])
        else
          # If there is a failure node, then the test case is marked as failing.
          # Which marks the test suite as failing.
          included_failing = true
          TestCase.new(snippet[:name], "fail", snippet[:snippet], failure["message"]?, output, snippet[:task_id])
        end
      else
        included_failing = true
        TestCase.new(snippet[:name], "error", snippet[:snippet], "Test case not found", nil, snippet[:task_id])
      end
    end

    puts "* Grouping solution ✅"

    # If the result array contains any failing test cases, then the test suite is marked as failing.
    if included_failing
      File.write(result_file_path, TestSuite.new("fail", nil, test_cases).to_json)
    else
      File.write(result_file_path, TestSuite.new("pass", nil, test_cases).to_json)
    end

    puts "* Writing result file ✅"
  end

  # The parse_spec_file method is used to parse the spec file.
  # It parses it by using ast parsing and then traversing the ast.
  # The information is gathered by using the TestVisitor class.
  #
  # This method takes the following arguments:
  # - *spec_file_path* - The path to the spec file
  #
  # Example:
  # ```
  # parse_spec_file("/tmp/spec.cr")
  # ```
  private def self.parse_spec_file(spec_file_path : String) : Array(NamedTuple(snippet: String, name: String, task_id: Int32?))
    spec_file_content = File.read(spec_file_path)
    parser = Crystal::Parser.new(spec_file_content)
    parsed_spec_file = parser.parse
    test_visitor = TestVisitor.new(spec_file_content.split("\n"))
    test_visitor.accept(parsed_spec_file)
    test_visitor.result
  end

  # Parses the standard output file and returns the parsed result.
  # The file is a json file that is written by the **setup_test_file.cr** file.
  # 
  # After the file is parsed it is deleted.
  # This is because the file is always appended to,
  # Thereby if not deleted, the file would include the output from previous test runs.
  private def self.parse_standard_output : JSON::Any
    standard_output = File.read("/tmp/output.json")
    File.delete("/tmp/output.json")
    JSON.parse(standard_output)
  end

  # The parse_xml method is used to parse the junit xml file.
  # The method returns the testsuite node of the xml file.
  #
  # If the file is not a valid junit xml file, then an error is raised.
  #
  # This method takes the following arguments:
  # - *junit_file_path* - The path to the junit xml file
  #
  # Example:
  # ```
  # parse_xml("/tmp/junit.xml")
  # ```
  private def self.parse_xml(junit_file_path : String) : XML::Node
    junit_xml_content = File.read(junit_file_path)
    junit_xml = XML.parse(junit_xml_content)
    testsuit = junit_xml.children.find { |node| node.name == "testsuite" }
    if testsuit.nil?
      raise "Invalid junit xml"
    end
    testsuit
  end
end

# Assiging ARGV values:
spec_output = ARGV[0]?
output_file = ARGV[1]?
junit_file = ARGV[2]?
result_file = ARGV[3]?

# If any of the arguments are nil (isn't given), then the usage is printed.
if spec_output.nil? || output_file.nil? || junit_file.nil? || result_file.nil?
  puts "Usage: crystal run test_runner.cr -- <spec_output> <output_file> <junit_file> <result_file>"
else
  TestRunner.execute(spec_output, output_file, junit_file, result_file)
end
