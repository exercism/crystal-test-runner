require "compiler/crystal/syntax"
require "json"
require "./test_visitor.cr"
require "xml"

module TestRunner
  class TestCase
    include JSON::Serializable
    property name : String
    property status : String
    property test_code : String
    property message : String?
    property output : String?
    property task_id : Int32?

    def initialize(name : String, status : String, test_code : String, message : String?, output : String?, task_id : Int32?)
      @name = name
      @status = status
      @test_code = test_code
      @message = message
      @output = output
      @task_id = task_id
    end
  end

  class TestSuite
    include JSON::Serializable
    property version : Int32 = 3
    property status : String
    property message : String?
    property tests : Array(TestCase)?

    def initialize(status : String, message : String?, tests : Array(TestCase)?)
      @status = status
      @tests = tests
      @message = message
    end
  end

  def self.execute(spec_file : String, capture_file : String, junit_file : String, result_file : String)
    included_failing = false

    unless File.exists?(junit_file)
      puts "* Failed finding junit xml ❌"
      error_message = File.read(capture_file)
      File.write(result_file, TestSuite.new("error", error_message, nil).to_json)
      exit(0)
    end

    junit_testsuite = parse_xml(junit_file)
    puts "* Reading junit xml ✅"

    parsed_spec_file = parse_spec_file(spec_file)
    puts "* Reading spec file ✅"

    parsed_standard_output = parse_standard_output()
    puts "* Parsing standard output ✅"

    result = parsed_spec_file.map_with_index do |snippet, index|
      test_case = junit_testsuite.children.find do |test_case|
        name = test_case["name"]?
        if name.nil?
          false
        else
          name == snippet[:name]
        end
      end
      if test_case
        if parsed_standard_output[index].to_s.empty?
          output = nil
        else
          output = parsed_standard_output[index].to_s
        end

        failure = test_case.children.find { |node| node.name == "failure" }

        if failure.nil?
          TestCase.new(snippet[:name], "pass", snippet[:snippet], nil, output, snippet[:task_id])
        else
          included_failing = true
          TestCase.new(snippet[:name], "fail", snippet[:snippet], failure["message"]?, output, snippet[:task_id])
        end
      else
        included_failing = true
        TestCase.new(snippet[:name], "error", snippet[:snippet], "Test case not found", nil, snippet[:task_id])
      end
    end

    puts "* Grouping solution ✅"

    if included_failing
      File.write(result_file, TestSuite.new("fail", nil, result).to_json)
    else
      File.write(result_file, TestSuite.new("pass", nil, result).to_json)
    end

    puts "* Writing result file ✅"
  end

  private def self.parse_spec_file(file : String) : Array(NamedTuple(snippet: String, name: String, task_id: Int32?))
    spec_file_content = File.read(file)
    parser = Crystal::Parser.new(spec_file_content)
    parsed_spec_file = parser.parse
    test_visitor = TestVisitor.new(spec_file_content.split("\n"))
    test_visitor.accept(parsed_spec_file)
    test_visitor.result
  end

  private def self.parse_standard_output : JSON::Any
    standard_output = File.read("/tmp/output.json")
    File.delete("/tmp/output.json")
    JSON.parse(standard_output)
  end

  private def self.parse_xml(junit_file : String) : XML::Node
    junit_xml_content = File.read(junit_file)
    junit_xml = XML.parse(junit_xml_content)
    testsuit = junit_xml.children.find { |node| node.name == "testsuite" }
    if testsuit.nil?
      raise "Invalid junit xml"
    end
    testsuit
  end
end

spec_output = ARGV[0]?
output_file = ARGV[1]?
junit_file = ARGV[2]?
result_file = ARGV[3]?

if spec_output.nil? || output_file.nil? || junit_file.nil? || result_file.nil?
  puts "Usage: crystal run test_runner.cr -- <spec_output> <output_file> <junit_file> <result_file>"
else
  TestRunner.execute(spec_output, output_file, junit_file, result_file)
end
