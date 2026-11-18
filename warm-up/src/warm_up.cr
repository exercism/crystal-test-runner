module WarmUp
  def self.hey(input : String) : String
    words = input.split(' ', remove_empty: true).map(&.downcase)
    counts = Hash(String, Int32).new(0)
    words.each { |word| counts[word] += 1 }
    puts counts.size
    "#{words.join(", ")} #{counts.values.sum}"
  end

  def self.digits(number : Int32) : Array(Int32)
    number.to_s.chars.map(&.to_i)
  end

  def self.average(numbers : Array(Float64)) : Float64
    raise ArgumentError.new("empty") if numbers.empty?
    numbers.sum / numbers.size
  end
end
