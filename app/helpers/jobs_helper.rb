module JobsHelper

    def tweetButtonText
        return "https://twitter.com/intent/tweet?text=" + @job.company.name + " is looking for a " + @job.role + ". Read more on DevCongress Jobs, " + job_url + (" &hash;devcongressjobs &hash;hiring via @DevCongress").html_safe
    end

    def fbButtonText
        return "https://www.facebook.com/sharer.php?u=" + job_url
    end

end
