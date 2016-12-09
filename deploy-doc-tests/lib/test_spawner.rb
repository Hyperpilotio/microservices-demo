def spawn_travis_tests travis, tests
  cron_build_number = ENV["TRAVIS_BUILD_NUMBER"]
  log(:info, "Running in travis, creating a build with multiple jobs")
  request = {
    message: "[deployment-daily-ci] spawned by build ##{cron_build_number}",
    branch: "master",
    config: reset_dot_travis_yml.merge({
      languge: "generic",
      sudo: true,
      services: ["docker"],
      install: ["gem install deploy_doc"],
      env: {
        global: [ "SPAWNED_BY_CRON_BUILD=#{cron_build_number}" ],
        matrix: tests.map { |test| "TEST_DOCUMENTATION_FOR=#{test.markdown_file}" }
      },
      script: ["deploy_doc $TEST_DOCUMENTATION_FOR -r"]
    })
  }
  
  request_result = travis.create_request(request)

  log(:info, "Created request #{request_result["id"]}")
end

DOT_TRAVIS_YML_WHITELIST = ["notifications"]
def reset_dot_travis_yml
  reset = {}
  yaml = YAML.load(File.read(REPO_ROOT.join(".travis.yml")))

  yaml.each do |key, value|
    if DOT_TRAVIS_YML_WHITELIST.include?(key)
      reset[key] = value
    else
      reset_value = case value
                    when Hash then {}
                    when Array then []
                    when String then ""
                    when Numeric then 0
                    else raise("Unknown reset  value for #{value.inspect}")
                    end
      reset[key] = reset_value
    end
  end

  reset
end
