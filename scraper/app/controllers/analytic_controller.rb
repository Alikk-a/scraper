class AnalyticController < ApplicationController
  require 'engtagger'

  def index
    @jobs = UpworkJob.all.limit(3).order(:id)

    titles = []

    jobs_all = UpworkJob.all

    jobs_all.each do |job|
      titles.append(job.title)
    end

    tagger = EngTagger.new
    lemmatized_titles = titles.map do |title|
      tagged = tagger.add_tags(title.downcase)
      # tagger.get_noun_phrases(tagged).keys  # Gets the base form of the words
      tagger.get_adjectives(tagged).keys  # Gets the base form of the words
    end
    @tag = tagger

    def find_flexible_ngrams(words, window_size = 2)
      ngrams = []

      # 2 слова
      # words.each_with_index do |word, index|
      #   ((index+1)...[index + window_size, words.length].min).each do |i|
      #     ngrams << [word, words[i]]
      #   end
      # end

      words.each_with_index do |word, index|
        ((index+1)...[index + window_size, words.length].min).each do |i|
          ngrams << [word, words[i]]
        end
      end

      ngrams
    end

    flexible_ngrams = lemmatized_titles.flat_map { |title| find_flexible_ngrams(title) }

    ngram_counts = flexible_ngrams.each_with_object(Hash.new(0)) { |ngram, counts| counts[ngram] += 1 }

    @expresions = []
    ngram_counts.sort_by { |_, count| -count }.each do |ngram, count|
      @expresions.append("#{ngram}: #{count}")
    end

  end
end
