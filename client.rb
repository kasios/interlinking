require "test/unit"
require "rest_client"
require "json"

class TestRESTClient < Test::Unit::TestCase
  
  def setup
    @connString = "http://localhost:4567" #Input file variables.
    puts "\nUsing: #{@connString}"
  end
 
  def teardown
    ## Nothing really
  end
  
  #Assert types for unit tests:
  #http://en.wikibooks.org/wiki/Ruby_Programming/Unit_testin
  
  def test_toolSilkRespFieldsSpecific
    response = RestClient.get "#{@connString}/tool/silk-agrovoc/response-fields/response1"
    puts response.body
    assert( response.body,"Failed test opening a response field of a tool.\n" )
  end
  
  def test_toolSilkRespFields
    response = RestClient.get "#{@connString}/tool/silk-agrovoc/response-fields"
    puts response.body
    assert( response.body,"Failed test opening specific tool's response fields\n" )
  end
  
  def test_toolSilk
    response = RestClient.get "#{@connString}/tool/silk-agrovoc"
    puts response.body
    assert( response.body,"Failed test opening specific tool\n" )
  end
  
  def test_toolKea
    response = RestClient.get "#{@connString}/tool/kea-agrovoc"
    puts response.body
    assert( response.body,"Failed test opening specific tool\n" )
  end
  
  def test_toolList
    response = RestClient.get "#{@connString}/tool/list"
    puts response.body
    assert( response.body,"Failed test listing tools \n" )
  end
  
  def test_supportedInput
    response = RestClient.get "#{@connString}/input/text/plain"
    puts response.body
    assert( response.body,"Failed test supported specific input.\n" )
  end
  
  def test_supportedInputs
    response = RestClient.get "#{@connString}/input/supported"
    puts response.body
    assert( response.body,"Failed test supported inputs.\n" )
  end
 
  def test_fromtext
    data = ""
    File.open("testFiles/exampleText", "r").each_line do |line|
      data+=line
    end
    post = RestClient.post "#{@connString}/fromtext/links/", {
        "tool" => "silk-agrovoc", 
        "text" => data,
        "limit" => "10"
    }
    puts post.body
    assert( post.body,"Failed test supported inputs.\n" )
  end
  
  def test_fromurisilk
    data = "http://textuploader.com/d8t9/raw"
    post = RestClient.post "#{@connString}/text/links/", {
        "tool" => "silk-agrovoc", 
        "text" => data,
        "limit" => "10"
    }
    puts post.body
    assert( post.body,"Failed test supported inputs.\n" )
  end
  
  def test_fromuri
    data = "http://textuploader.com/d8t9/raw"
    post = RestClient.post "#{@connString}/text/links/", {
        "tool" => "kea-agrovoc", 
        "text" => data,
        "limit" => "10"
    }
    puts post.body
    assert( post.body,"Failed test supported inputs.\n" )
  end
end