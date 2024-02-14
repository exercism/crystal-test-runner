class Bob
  def self.hey(string : String)
    raise ArgumentError.new
    case string
    when .blank?
      "Fine. Be that way!"
    else
      "Whatevah."
    end
  end
end
