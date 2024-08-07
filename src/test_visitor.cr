require "compiler/crystal/syntax"

# This visitor is used to extract the test snippets from the source code.
# It is used to get the test_code snippets for the test cases.
# But also to get a list of the name of all the test cases.
# Last but not least it also adds the task_id to the test cases.
class TestVisitor < Crystal::Visitor
  getter result = [] of NamedTuple(snippet: String, name: String, task_id: Int32?)

  # The task_id is used to give the test cases a task_id.
  @task_id : Int32? = nil

  # The initilization of the visitor.
  # The source_code is used to get the test snippets.
  # The breadcrumbs are used to get the name of the test cases.
  def initialize(@source_code : Array(String))
    @breadcrumbs = [] of String
  end

  # This method is used to visit the nodes of the AST, specifically the Call nodes.
  # If the name is either describe, it or pending it will call the corresponding method.
  # Otherwise will it not dig deeper into the AST.
  def visit(node : Crystal::Call)
    case node.name
    when "describe"
      handle_visit_describe_call(node)
    when "it", "pending"
      handle_visit_it_call(node)
    end

    false
  end

  # This method is used to end the visit of the nodes of the AST, specifically the Call nodes.
  def end_visit(node : Crystal::Call)
    if node.name == "describe"
      handle_end_visit_describe_call(node)
    end
  end

  # This method is used to visit the nodes of the AST, which hasn't been handled by the other visit methods.
  # It tells the visitor to dig deeper into the AST.
  def visit(node)
    true
  end

  private def handle_visit_describe_call(node : Crystal::Call)
    if tags = node.named_args
      if tags.any? { |tag| tag.value.as(Crystal::StringLiteral).value.to_s == "optional" }
        return
      end
      @task_id = extract_task_id?(tags[0].value.as(Crystal::StringLiteral).value)
    else
      @task_id = nil
    end

    case arg = node.args[0]
    when Crystal::StringLiteral
      @breadcrumbs << arg.value
    when Crystal::Path
      @breadcrumbs << arg.to_s
    end
    accept(node.block.not_nil!)
  end

  private def handle_end_visit_describe_call(node : Crystal::Call)
    if tags = node.named_args
      if tags.any? { |tag| tag.value.as(Crystal::StringLiteral).value.to_s == "optional" }
        return
      end
    end
    @breadcrumbs.pop
    true
  end

  private def handle_visit_it_call(node : Crystal::Call)
    if tags = node.named_args
      if tags.any? { |tag| tag.value.as(Crystal::StringLiteral).value.to_s == "optional" }
        return
      end
    end
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
    @result << {snippet: snippet, name: name, task_id: @task_id}
  end

  private def extract_task_id?(text)
    if text.starts_with?("task_id=")
      text[8..-1].to_i?
    else
      nil
    end
  end
end
