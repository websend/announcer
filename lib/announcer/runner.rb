require 'rest-client'

class Job < Struct.new(:name, :status)
end

module Announcer
  class Runner
    def self.run
      new.run
    end

    def run
      Announcer.configure

      jobs_resource = RestClient::Resource.new("#{Announcer.configuration.jenkins_url}/api/json?tree=jobs[name,color]",
                                                  Announcer.configuration.github_username,
                                                  Announcer.configuration.github_access_token)

      jobs = {}

      loop do
        response = JSON.parse(jobs_resource.get)

        response["jobs"].each do |job|
          previous_job = jobs[job["name"]]

          if previous_job
            if job_has_failed?(previous_job, job)
              announce_failure(job)
            elsif job_has_started?(previous_job, job)
              announce_build_started(job)
            end
          else
            if job_is_broken?(job)
              announce_broken(job)
            elsif job_has_started?(job)
              announce_build_started(job)
            end
          end

          jobs[job["name"]] = Job.new(job["name"], job["color"])
        end

        print "."
        sleep 5
      end
    end

    def job_has_failed?(previous_job, job)
      previous_job.status != "red" && job["color"] == "red"
    end

    def job_has_started?(previous_job=nil, job)
      if previous_job
        previous_job.status !~ /anime/
      else
        true
      end && job["color"] =~ /anime/
    end

    def job_is_broken?(job)
      job["color"] == "red"
    end

    def culprit(job)
      response = RestClient::Resource.new("#{Announcer.configuration.jenkins_url}/job/#{job["name"]}/lastBuild/api/json?tree=culprits[fullName]",
                                          Announcer.configuration.github_username,
                                          Announcer.configuration.github_access_token).get
      culprits = JSON.parse(response)
      culprits["culprits"].first["fullName"]
    rescue
      "Jan met de korte achternaam"
    end

    def announce_failure(job)
      system "say -v xander Droeftoeter #{culprit(job)} heeft #{phonetic_name[job["name"]]} kapot gemaakt. Ga eens snel fixen beschuitlul!"
      puts "#{job["name"]} has failed, broken by #{culprit(job)}"
    end

    def announce_broken(job)
      system "say -v xander Helaas, de bild van #{phonetic_name[job["name"]]} is nog steeds kapot. Het wordt hoogste tijd dat #{culprit(job)} daar wat aan gaat doen."
      puts "#{job["name"]} is still broken by #{culprit(job)}"
    end

    def announce_build_started(job)
      system "say -v xander Er is een nieuwe bild van #{phonetic_name[job["name"]]} gestart. Benieuwd naar het resultaat."
      puts "#{job["name"]} is building"
    end

    def phonetic_name
      {
        "Hare" => "Hèèr",
        "Mother" => "Moeder",
        "Frontend" => "Front End",
        "order-insertion" => "Order In-sursion"
      }
    end
  end
end
