require 'test_helper'

silence_warnings do
  Post = Struct.new(:title, :author_name, :body, :secret, :written_on, :cost)
  Post.class_eval do
    alias_method :title_before_type_cast, :title unless respond_to?(:title_before_type_cast)
    alias_method :body_before_type_cast, :body unless respond_to?(:body_before_type_cast)
    alias_method :author_name_before_type_cast, :author_name unless respond_to?(:author_name_before_type_cast)
    alias_method :secret?, :secret

    def new_record=(boolean)
      @new_record = boolean
    end

    def new_record?
      @new_record
    end

    attr_accessor :author
    def author_attributes=(attributes); end

    attr_accessor :comments
    def comments_attributes=(attributes); end
      
    def self.human_attribute_name(attr)
      attr.humanize
    end
  end

  class Comment
    attr_reader :id
    attr_reader :post_id
    def initialize(id = nil, post_id = nil); @id, @post_id = id, post_id end
    def save; @id = 1; @post_id = 1 end
    def new_record?; @id.nil? end
    def to_param; @id; end
    def name
      @id.nil? ? "new #{self.class.name.downcase}" : "#{self.class.name.downcase} ##{@id}"
    end
    def errors()
      Class.new{
        def on(field); "can't be empty" if field == "post_id"; end
        def empty?() false end
        def count() 1 end
        def full_messages() [ "Post can't be empty" ] end
      }.new
    end
    def self.human_attribute_name(attr)
      attr.humanize
    end
  end

  class Author < Comment
    attr_accessor :post
    def post_attributes=(attributes); end
  end
end

#TODO input test
#TODO fieldset_for custom builder
class LabeledFormTest < ActionView::TestCase
  tests DiMarcello::LabeledForm::LabeledFormHelper

  def setup
    @post = Post.new
    @comment = Comment.new
    def @post.errors()
      Class.new{
        def on(field); "can't be empty" if field == "author_name"; end
        def empty?() false end
        def count() 1 end
        def full_messages() [ "Author name can't be empty" ] end
      }.new
    end
    def @post.id; 123; end
    def @post.id_before_type_cast; 123; end
    def @post.to_param; '123'; end

    @post.title       = "Hello World"
    @post.author_name = ""
    @post.body        = "Back to the hill and over it again!"
    @post.secret      = 1
    @post.written_on  = Date.new(2004, 6, 15)

    @controller = Class.new do
      attr_reader :url_for_options
      def url_for(options)
        @url_for_options = options
        "http://www.example.com"
      end
    end
    @controller = @controller.new
  end

  def test_labeled_form_for
    labeled_form_for(:post, @post, :html => { :id => 'create-post' }) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
      concat f.submit('Create post')
    end

    expected  = "<form action='http://www.example.com' id='create-post' method='post'>"
    expected << "<p>" +
                "<label for='post_title' title='Title'>Title</label>" +
                "<input name='post[title]' size='30' type='text' id='post_title' value='Hello World' />" +
                "</p>"
    expected << "<p>" + 
                "<label for='post_body' title='Body'>Body</label>" +
                "<textarea name='post[body]' id='post_body' rows='20' cols='40'>Back to the hill and over it again!</textarea>" + 
                "</p>"
    expected << "<p>" + 
                "<label for='post_secret' title='Secret'>Secret</label>" +
                "<input name='post[secret]' type='hidden' value='0' />" +
                "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />" +
                "</p>"
    expected << "<p>" + 
                "<input name='commit' id='post_submit' type='submit' value='Create post' />" +
                "</p>"
    expected << "</form>"

    assert_dom_equal expected, output_buffer
  end

  def test_labeled_form_for_with_custom_labels
    labeled_form_for(:post, @post, :html => { :id => 'create-post' }) do |f|
      concat f.text_field(:title, :label => "L")
      concat f.text_area(:body, :label => "L")
      concat f.check_box(:secret, :label => "L")
    end

    expected  = "<form action='http://www.example.com' id='create-post' method='post'>"
    expected << "<p>" +
                "<label for='post_title' title='Title'>L</label>" +
                "<input name='post[title]' size='30' type='text' id='post_title' value='Hello World' />" +
                "</p>"
    expected << "<p>" + 
                "<label for='post_body' title='Body'>L</label>" +
                "<textarea name='post[body]' id='post_body' rows='20' cols='40'>Back to the hill and over it again!</textarea>" + 
                "</p>"
    expected << "<p>" + 
                "<label for='post_secret' title='Secret'>L</label>" +
                "<input name='post[secret]' type='hidden' value='0' />" +
                "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />" +
                "</p>"
    expected << "</form>"

    assert_dom_equal expected, output_buffer
  end
  
  def test_labeled_form_for_without_labels
    labeled_form_for(:post, @post, :html => { :id => 'create-post' }) do |f|
      concat f.text_field(:title, :label => false)
      concat f.text_area(:body, :label => false)
      concat f.check_box(:secret, :label => false)
      concat f.submit('Create post')
    end

    expected  = "<form action='http://www.example.com' id='create-post' method='post'>"
    expected << "<p>" +
                "<input name='post[title]' size='30' type='text' id='post_title' value='Hello World' />" +
                "</p>"
    expected << "<p>" + 
                "<textarea name='post[body]' id='post_body' rows='20' cols='40'>Back to the hill and over it again!</textarea>" + 
                "</p>"
    expected << "<p>" + 
                "<input name='post[secret]' type='hidden' value='0' />" +
                "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />" +
                "</p>"
    expected << "<p>" + 
                "<input name='commit' id='post_submit' type='submit' value='Create post' />" +
                "</p>"
    expected << "</form>"

    assert_dom_equal expected, output_buffer
  end
  
  def test_labeled_form_for_without_wrap
    labeled_form_for(:post, @post, :html => { :id => 'create-post' }) do |f|
      concat f.text_field(:title, :wrap => false)
      concat f.text_area(:body, :wrap => false)
      concat f.check_box(:secret, :wrap => false)
    end

    expected  = "<form action='http://www.example.com' id='create-post' method='post'>"
    expected << "<label for='post_title' title='Title'>Title</label>" +
                "<input name='post[title]' size='30' type='text' id='post_title' value='Hello World' />"
    expected << "<label for='post_body' title='Body'>Body</label>" +
                "<textarea name='post[body]' id='post_body' rows='20' cols='40'>Back to the hill and over it again!</textarea>" 
    expected << "<label for='post_secret' title='Secret'>Secret</label>" +
                "<input name='post[secret]' type='hidden' value='0' />" +
                "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"
    expected << "</form>"

    assert_dom_equal expected, output_buffer
  end
  
  def test_labeled_form_for_with_custom_wrap
    labeled_form_for(:post, @post, :html => { :id => 'create-post' }) do |f|
      concat f.text_field(:title, :wrap => :div)
      concat f.text_area(:body, :wrap => :div)
      concat f.check_box(:secret, :wrap => :div)
    end

    expected  = "<form action='http://www.example.com' id='create-post' method='post'>"
    expected << "<div>" +
                "<label for='post_title' title='Title'>Title</label>" +
                "<input name='post[title]' size='30' type='text' id='post_title' value='Hello World' />" +
                "</div>"
    expected << "<div>" + 
                "<label for='post_body' title='Body'>Body</label>" +
                "<textarea name='post[body]' id='post_body' rows='20' cols='40'>Back to the hill and over it again!</textarea>" + 
                "</div>"
    expected << "<div>" + 
                "<label for='post_secret' title='Secret'>Secret</label>" +
                "<input name='post[secret]' type='hidden' value='0' />" +
                "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />" +
                "</div>"
    expected << "</form>"

    assert_dom_equal expected, output_buffer
  end
  
  def test_labeled_form_for_without_object
    labeled_form_for(:post, :html => { :id => 'create-post' }) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected  = "<form action='http://www.example.com' id='create-post' method='post'>"
    expected << "<p>" +
                "<label for='post_title' title='Title'>Title</label>" +
                "<input name='post[title]' size='30' type='text' id='post_title' value='Hello World' />" +
                "</p>"
    expected << "<p>" + 
                "<label for='post_body' title='Body'>Body</label>" +
                "<textarea name='post[body]' id='post_body' rows='20' cols='40'>Back to the hill and over it again!</textarea>" + 
                "</p>"
    expected << "<p>" + 
                "<label for='post_secret' title='Secret'>Secret</label>" +
                "<input name='post[secret]' type='hidden' value='0' />" +
                "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />" +
                "</p>"
    expected << "</form>"

    assert_dom_equal expected, output_buffer
  end

  def test_nested_labeled_fieldset_for_on_a_nested_attributes_one_to_one_association
    labeled_form_for(:post, @post) do |f|
      f.fieldset_for(:comment, @post) do |c|
        concat c.text_field(:title)
      end
    end

    expected = "<form action='http://www.example.com' method='post'>" +
                 "<fieldset>" + 
                   "<legend>Comment</legend>" + 
                   "<p>" +
                     "<label for='post_comment_title' title='Title'>Title</label>" +
                     "<input name='post[comment][title]' size='30' type='text' id='post_comment_title' value='Hello World' />" +
                   "</p>" +
                 "</fieldset>" + 
               "</form>"

    assert_dom_equal expected, output_buffer
  end
  
  def test_nested_labeled_fieldset_for_on_a_nested_attributes_collection_association
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }
    labeled_form_for(:post, @post) do |f|
      f.fieldset_for(:comments) do |c|
        concat c.text_field(:name)
      end
    end

    expected = "<form action='http://www.example.com' method='post'>" +
                 "<fieldset>" + 
                   "<legend>Comments</legend>" +
                     '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="1" />' +
                   "<p>" +
                     "<label title='Name' for='post_comments_attributes_0_name'>Name</label>" + 
                     '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" size="30" type="text" value="comment #1" />' +
                   "</p>" + 
                   '<input id="post_comments_attributes_1_id" name="post[comments_attributes][1][id]" type="hidden" value="2" />' +
                   "<p>" + 
                     "<label title='Name' for='post_comments_attributes_1_name'>Name</label>" + 
                     '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" size="30" type="text" value="comment #2" />' +
                   "</p>" + 
                 "</fieldset>" + 
               "</form>"

    assert_dom_equal expected, output_buffer
  end

  def test_nested_labeled_fieldset_for_without_legend
    labeled_form_for(:post, @post) do |f|
      f.fieldset_for(:comment, @post, :legend => false) do |c|
        concat c.text_field(:title)
      end
    end

    expected = "<form action='http://www.example.com' method='post'>" +
                 "<fieldset>" + 
                   "<p>" +
                     "<label for='post_comment_title' title='Title'>Title</label>" +
                     "<input name='post[comment][title]' size='30' type='text' id='post_comment_title' value='Hello World' />" +
                   "</p>" +
                 "</fieldset>" + 
               "</form>"

    assert_dom_equal expected, output_buffer
  end

  def test_nested_labeled_fieldset_for_with_custom_legend
    labeled_form_for(:post, @post) do |f|
      f.fieldset_for(:comment, @post, :legend => "Legend") do |c|
        concat c.text_field(:title)
      end
    end

    expected = "<form action='http://www.example.com' method='post'>" +
                 "<fieldset>" + 
                   "<legend>Legend</legend>" + 
                   "<p>" +
                     "<label for='post_comment_title' title='Title'>Title</label>" +
                     "<input name='post[comment][title]' size='30' type='text' id='post_comment_title' value='Hello World' />" +
                   "</p>" +
                 "</fieldset>" + 
               "</form>"

    assert_dom_equal expected, output_buffer
  end

  def test_nested_labeled_fieldset_for_with_html_options
    labeled_form_for(:post, @post) do |f|
      f.fieldset_for(:comment, @post, :class => "selector") do |c|
        concat c.text_field(:title)
      end
    end

    expected = "<form action='http://www.example.com' method='post'>" +
                 "<fieldset class='selector'>" + 
                   "<legend>Comment</legend>" + 
                   "<p>" +
                     "<label for='post_comment_title' title='Title'>Title</label>" +
                     "<input name='post[comment][title]' size='30' type='text' id='post_comment_title' value='Hello World' />" +
                   "</p>" +
                 "</fieldset>" + 
               "</form>"

    assert_dom_equal expected, output_buffer
  end
  
  protected
  
  def protect_against_forgery?
    false
  end
  
  private
  
end
