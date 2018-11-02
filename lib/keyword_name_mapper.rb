require 'yaml'

class KeywordNameMapper

  KEYWORD_STRINGS = YAML.load_file(File.join(File.dirname(__FILE__), "/../keywords.yml")).fetch('keywords')

  def self.translate(keyword)
    KEYWORD_STRINGS.fetch(keyword.to_s)
  end

  def self.configure_i18n
    I18n.backend.available_locales.each do |locale|
      # Default I18n for any keyword that wasn't manually set in the I18n YAML
      filtered = KEYWORD_STRINGS.select {|keyword, translation|
        I18n.t("plugins.onbase_document_keyword.#{keyword}", :default => "", :locale => locale).empty?
      }

      filtered = Hash[filtered.map{|k, v| [k.intern, v]}]

      I18n.backend.store_translations(locale, {:plugins => {:onbase_document_keyword => filtered}})
    end
  end

end
