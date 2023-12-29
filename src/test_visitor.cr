require "compiler/crystal/syntax"

class TestVisitor < Crystal::Visitor
  getter result = [] of NamedTuple(snippet: String, name: String, task_id: Int32?)

  def initialize(source_code : Array(String))
    @level = 0
    @breadcrumbs = [] of String
    @source_code = source_code
  end

  def visit(node : Crystal::Call)
    case node.name
    when "describe"
      handle_visit_describe_call(node)
    when "it", "pending"
      handle_visit_it_call(node)
    end

    false
  end

  def end_visit(node : Crystal::Call)
    if node.name == "describe"
      handle_end_visit_describe_call(node)
    end
  end

  def visit(node)
    true
  end

  private def handle_visit_describe_call(node : Crystal::Call)
    @level += 1 if @breadcrumbs.size == 1
    case arg = node.args[0]
    when Crystal::StringLiteral
      @breadcrumbs << arg.value
    when Crystal::Path
      @breadcrumbs << arg.to_s
    end
    accept(node.block.not_nil!)
  end

  private def handle_end_visit_describe_call(node : Crystal::Call)
    @breadcrumbs.pop
    true
  end

  private def handle_visit_it_call(node : Crystal::Call)
    label = node.args[0].not_nil!.as(Crystal::StringLiteral).value
    current_test_name_prefix = @breadcrumbs.join(" ")
    name = "#{current_test_name_prefix} #{label}"

    start_location = node.block.not_nil!.body.location.not_nil!
    end_location = node.block.not_nil!.body.end_location.not_nil!

    start_column_index = start_location.column_number - 1
    start_line_index = start_location.line_number - 1
    end_line_index = end_location.line_number - 1

    snippet = @source_code[start_line_index..end_line_index]
    .map { |line| line[start_column_index..-1]? || "" }
    .join("\n")
    @result << {snippet: snippet, name: name, task_id: @level != 0 ? @level : nil}
  end
end
