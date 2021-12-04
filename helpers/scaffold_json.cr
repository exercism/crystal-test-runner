require "compiler/crystal/syntax"
require "json"

DESCRIBE_PREFIX = /^\s*describe\s/
TEST_PREFIX     = /^\s*it\s/
PENDING_PREFIX  = /^\s*pending\s/
BLOCK_END       = /^\s*end/
CAPTURE_QUOTE   = /"([^"]+)"/

class TestCase
  property code, name

  def initialize(name : String, code : String)
    @name = name
    @code = code
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

class TestVisitor < Crystal::Visitor
  property tests, breadcrumbs

  def initialize
    @tests = Array(TestCase).new
    @breadcrumbs = Array(String).new
  end

  def current_test_name_prefix
    breadcrumbs.join(" ")
  end

  def visit(node : Crystal::Call)
    case node.name
    when "describe"
      handle_visit_describe_call(node)
    when "it"
      handle_visit_it_call(node)
    when "pending"
      handle_visit_it_call(node)
    end

    false
  end

  def end_visit(node : Crystal::Call)
    case node.name
    when "describe"
      handle_end_visit_describe_call(node)
    end
  end

  def visit(node)
    true
  end

  private def handle_visit_describe_call(node : Crystal::Call)
    @breadcrumbs << node.args[0].not_nil!.as(Crystal::StringLiteral).value
    accept(node.block.not_nil!)
  end

  private def handle_end_visit_describe_call(node : Crystal::Call)
    breadcrumbs.pop
    return true
  end

  private def handle_visit_it_call(node : Crystal::Call)
    label = node.args[0].not_nil!.as(Crystal::StringLiteral).value
    name = "#{current_test_name_prefix} #{label}"
    code = node.block.not_nil!.body.to_s
    @tests << TestCase.new(name, code)
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

test_file_content = File
  .read(test_file)

parser = Crystal::Parser.new(test_file_content)
ast = parser.parse

visitor = TestVisitor.new
visitor.accept(ast)

scaffold =
  JSON.build do |json|
    json.object do
      json.field "version", 2
      json.field "status", nil
      json.field "message", nil
      json.field "tests", visitor.tests
    end
  end

puts "* Writing scaffold json to: #{output_file} 🖊"

File.write(output_file, scaffold)
puts "* All done converting spec to scaffold json 🏁"
