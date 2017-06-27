require_relative 'directory'
#require_relative 'relation/base'
  @obj = Classrubrowser::Parser::Directory.new("/home/shantanu/RubyCodes");
  @obj.parse
  @obj.definitions
  @obj.relations


  #Create map for all
=begin
  @obj.parsers.each do |parsedForm|
    puts parsedForm.definitions
    puts parsedForm.relations
  end
=end

=begin
  puts "Hi"
  @obj.parsers[2].definitions.each do |defi|
    puts defi.line
  end
=end
p @obj.parsers[4].definitions
p @obj.parsers[4].ast

=begin
  puts @obj.parsers[6].ast

  puts @obj.parsers[2].relations[0].namespace
  puts @obj.parsers[2].relations[0].caller_namespace
  puts @obj.parsers[2].relations[0].file
  puts @obj.parsers[2].relations[0].line
  puts @obj.parsers[2].relations[0].cols
  puts @obj.parsers[2].relations[0].lastCols
  puts @obj.parsers[2].ast
=end
  #puts @obj.parsers[2].relations[1].caller_namespace
  #puts @obj.parsers[2].relations[2].namespace
  #puts @obj.parsers[2].relations[2].caller_namespace
  #puts @obj.parsers[2].relations[3].namespace
  #puts @obj.parsers[2].relations[3].caller_namespace