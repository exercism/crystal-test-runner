require "json"

DESCRIBE_PREFIX = /^\s*describe\s/
TEST_PREFIX     = /^\s*it\s/
PENDING_PREFIX  = /^\s*pending\s/
BLOCK_END       = /^\s*end/
CAPTURE_QUOTE   = /"([^"]+)"/

class TestCase
  property code_lines, depth, name

  def initialize(name : String, depth : Int32)
    @name = name
    @code_lines = Array(String).new
    @depth = depth
  end

  def code
    min_indent =
      code_lines.min_of do |line|
        stripped = line.lstrip
        line.size - stripped.size
      end

    code_lines.map { |line| line[min_indent..-1] }.join("\n")
  end

  def to_json(json)
    json.object do
      json.field "name", name
      json.field "test_code", code
      json.field "status", nil
      json.field "message", nil
      json.field "output", nil
    end
  end
end

class ParsingState
  property in_test, depth, depth_of_test_case, current, breadcrumbs, test_cases

  @breadcrumbs : Array(String)
  @current : Nil | TestCase
  @depth : Int32
  @test_cases : Array(TestCase)
  @in_test : Bool

  def initialize
    @depth = -1
    @test_cases = Array(TestCase).new
    @breadcrumbs = Array(String).new
    @in_test = false
  end

  def add_breadcrumb(line : String)
    match = line.match(CAPTURE_QUOTE)
    capture = match[1]? if match
    @breadcrumbs << capture if capture
    @depth += 1 if capture
  end

  def remove_breadcrumb
    breadcrumbs.pop
  end

  def current_name
    breadcrumbs.join(" ")
  end

  def found_test_case(line : String)
    raise "Found unexpected test case in a test case" if in_test

    @in_test = true
    test_case = TestCase.new(current_name, depth)
    @current = test_case
    @test_cases << test_case
  end

  def handle_end
    current_test_case_depth = current ? current.as(TestCase).depth : -1
    at_test_case_depth = current_test_case_depth == depth

    @depth -= 1
    if at_test_case_depth
      remove_breadcrumb
      @in_test = false
    end
  end

  def handle_line(line : String)
    if line.matches?(BLOCK_END)
      handle_end
    end

    current.as(TestCase).code_lines << line if in_test
  end
end

test_file = ARGV[0]?
output_file = ARGV[1]?

unless test_file && output_file
  puts <<-USAGE
    Usage:
    > scaffold_json <spec test file> <output json file>
    USAGE
  exit 1
end

puts "* Reading spec file: #{test_file} 📖"

tests = File
  .read(test_file)
  .lines
  .reduce(ParsingState.new) do |state, line|
    case line
    when .matches?(DESCRIBE_PREFIX)
      state.add_breadcrumb(line)
    when .matches?(TEST_PREFIX), .matches?(PENDING_PREFIX)
      state.add_breadcrumb(line)
      state.found_test_case(line)
    else
      state.handle_line(line)
    end

    state
  end
  .test_cases

scaffold =
  JSON.build do |json|
    json.object do
      json.field "version", 2
      json.field "status", nil
      json.field "message", nil
      json.field "tests", tests
    end
  end

puts "* Writing scaffold json to: #{output_file} 🖊"

File.write(output_file, scaffold)
puts "* All done converting spec to scaffold json 🏁"
