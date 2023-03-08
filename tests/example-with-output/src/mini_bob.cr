class Bob
  def self.hey(string : String)
    numbers = [[1, 5, 6], [5, 10], [2]]
    numbers.each do |number|
      number.each do |num|
        p num
        puts num
      end
    end
    "Whatever. #{string}"
  end

  def self.bye(string : String)
    p "Bye."
    puts 5
    "Bye."
  end
end
