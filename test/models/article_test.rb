require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "retrieves fixtures" do
    articles = Article.all
    assert_equal 2, articles.length
    ruby_article = articles.find { |a| a.title == "My ruby adventure" }
    rails_article = articles.find { |a| a.title == "Rails experiments" }

    assert_equal articles(:ruby), ruby_article
    assert_equal Status::PUBLIC, ruby_article.status
    assert_equal "My ruby adventure", ruby_article.title
    assert_equal "Here it is, I started some Ruby and now I'm writting some fixtures", ruby_article.body
    assert_equal Some("Ruby is nice"), ruby_article.summary
    assert ruby_article.status_public?
    assert_not ruby_article.status_archived?

    assert_equal articles(:rails), rails_article
    assert_equal Status::PRIVATE, rails_article.status
    assert_equal "Rails experiments", rails_article.title
    assert_equal "Draft article on Rails", rails_article.body
    assert_equal None(), rails_article.summary
    assert rails_article.status_private?
  end
  test "counts public" do
    assert_equal 1, Article.public_count
  end
  test "validates correctness" do
    Article.create!(status: Status::PUBLIC, title: "title", body: "body, body", summary: Some("sum"))
    assert_raise(ArgumentError) { Article.create!(status: "bad", title: "title", body: "body, body", summary: Some("sum")) }
    assert_raise(ActiveRecord::RecordInvalid) { Article.create!(status: nil, title: "title", body: "body, body", summary: Some("sum")) }
    assert_raise(ActiveRecord::RecordInvalid) { Article.create!(status: Status::PUBLIC, title: "", body: "body, body", summary: Some("sum")) }
    assert_raise(ActiveRecord::RecordInvalid) { Article.create!(status: Status::PUBLIC, title: "title", body: "body", summary: Some("sum")) }
  end
  test "persists and retrieves Article" do
    article = Article.create!(status: Status::PUBLIC, title: "title", body: "body, body, body", summary: Some("sum"))
    assert_equal article, Article.find_by_title("title")
    assert_equal article, Article.find_by_summary(Some("sum"))
  end
end
