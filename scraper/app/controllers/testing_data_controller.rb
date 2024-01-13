class TestingDataController < ApplicationController

  require 'roo'

  def index
    data_skills = UpworkJob.select("skills").where("cast(client_hire_rate as integer) > 30")
    skills = []

    data_skills.each do |row|
      row[:skills].each do |skill|
        skills << skill
      end
    end
    @skills_sorted = skills.sort
    @grouped = skills.group_by { |skill| skill }.sort_by { |skill| skill[1].length }.reverse

  end
end
