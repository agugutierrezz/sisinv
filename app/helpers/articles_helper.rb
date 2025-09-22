module ArticlesHelper
  def article_archived?(article)
    if article.respond_to?(:activo)
      article.activo == false
    elsif article.is_a?(Hash)
      article["activo"] == false || article["archivado"] == true
    else
      false
    end
  end
end
