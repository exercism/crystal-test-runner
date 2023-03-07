def fix_test_file(spec_input, spec_output)
  unless spec_input.nil?
    spec_file = File.read(spec_input).split("\n")
    index = spec_file.index {|x| x.includes?("describe")}
    unless index.nil?
      spec_file = spec_file.insert(index + 1, "around_each do |example|\noriginal_stdout = File.open(\"/dev/null\")\noriginal_stdout.reopen(STDOUT)\nIO.pipe do |reader, writer|\nSTDOUT.reopen(writer)\nbegin\nexample.run\nensure\nwriter.close\nSTDOUT.reopen(original_stdout)\nend\nadd = File.exists?(\"/tmp/ouput.json\") ? JSON.parse(File.read(\"/tmp/ouput.json\")).to_s[1..-2] + \", \" : \"\"\nFile.write(\"/tmp/ouput.json\", JSON.parse(\"[\" + add + \"\#{reader.gets_to_end.split(\"\n\")[..-2].join(\"\n\").inspect}]\"))\nend\nend\n")
    end
    unless spec_output.nil?
      File.write(spec_output, "require \"json\"\n" + spec_file.join("\n").gsub("pending", "it"))
    end
  end
end

spec_input = ARGV[0]?
spec_output = ARGV[1]?

fix_test_file(spec_input, spec_output)
