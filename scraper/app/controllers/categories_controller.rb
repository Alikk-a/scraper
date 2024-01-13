class CategoriesController < ApplicationController
  require 'roo'

  before_action :base_settings

  def index
   # --------- каждое вхождение в категорию - each task in many categories -----------------
    @category_counts = Hash.new { |hash, key| hash[key] = [0, 0] }

    def categorize_task(task, category_keywords)
      category_keywords.each do |category, keywords|
        if keywords.any? { |keyword| task[0].downcase.include?(keyword) }
          @category_counts[category][0] += 1
          @category_counts[category][1] += task[1]
        end
      end
    end

    @tasks.each do |task|
      categorize_task(task, @category_keywords)
    end

    display_categories(@category_counts)

  end

  def categories_inline
    # --------- каждое вхождение категории - в строку -----------------
    def categorize_task(task, category_keywords)
      match_categories = ''
      category_keywords.each do |category, keywords|
        if keywords.any? { |keyword| task.downcase.include?(keyword) }
          match_categories = match_categories + ' | ' + category.to_s
        end
      end
      match_categories
    end

    # Categorize tasks and count occurrences
    category_counts = Hash.new { |hash, key| hash[key] = [0, 0] }
    @tasks.each do |task|
      category = categorize_task(task[0], @category_keywords)
      category_counts[category][0] += 1
      category_counts[category][1] += task[1]
    end

    display_categories(category_counts)

    render :index
  end

  def display_categories(category_counts)
    # Display category counts
    @categories = []
    category_counts.each do |category, count|
      @categories.append([category, count[0], count[1]])
      # @categories.sort_by { |e| e[0].to_s }
    end
  end

  private

  def base_settings
    @category_keywords = {
        "Scraping Framework": ["scraping framework"],
        "Search Engine Optimization": ["search engine optimization"],
        "Natural Language Processing": ["natural language processing"],
        "Transaction Data Entry": ["transaction data entry"],
        "Data Labeling": ["data labeling"],
        "Shopify": ["shopify"],
        "Instagram": ["instagram"],
        "Facebook": ["facebook"],
        "LinkedIn": ["linkedin"],
        "Amazon": ["amazon"],
        "GIS": ["gis"],
        "Apollo": ["apollo"],
        "Visualization": ["visualization"],
        "Social Media": ["social media"],
        "Bot Development": ["bot development"],
        "Data Integration": ["data integration"],
        "ChatGPT": ["chatgpt"],
        "Git": ["git"],
        "Real Estate": ["real estate"],
        "OpenAI": ["openai"],
        "Data Processing": ["data processing"],
        "Communications": ["communications"],
        "B2B": ["b2b"],
        "Automation": ["automation"],
        "Proxy": ["proxy"],
        "Accuracy Verification": ["accuracy verification"],

        "Market Research": ["market research"],
        "Company Research": ["company research"],
        "Data Research": ["research", "find", "search"],

        "Email Marketing": ["email marketing"],
        "Data Cleaning": ["data cleaning"],
        "Data Analysis": ["analysis", "analyze", "data processing"],
        "App Development": ["app development", "software"],
        "Lead Generation": ["lead", "contact", "client", "prospect list"],
        "API": ["api"],
        "Web Scraping": ["scrape", "extract", "crawler"],
        "Others": [] # This will be used for tasks that don't fit other categories
    }

    @all_proposals = UpworkJob.where("cast(client_hire_rate as integer) >= 0").sum(:job_proposals)

    @all_jobs = UpworkJob.where("cast(client_hire_rate as integer) >= 0")
    @tasks = []
    @all_jobs.each do |row|
      combined_task = ["#{row.title} #{row.description} #{row.skills.to_s}", row.job_proposals]
      @tasks << combined_task
    end

  end

end

# ---------  первая попавщаяся категория ------------
# def categorize_task(task, category_keywords)
#   category_keywords.each do |category, keywords|
#     return category if keywords.any? { |keyword| task.downcase.include?(keyword) }
#   end
#   'Others'
# end
#--------------------------------------------

# def open_excel(file_path)
#   Roo::Spreadsheet.open(file_path)
# end
# file_path = './scrap_data.xlsx'
# xlsx = open_excel(file_path)
# xlsx.sheet(0).each_row_streaming(offset: 0) do |row| # offset: 1 to skip header
#   title = row[0].to_s
#   description = row[1].to_s
