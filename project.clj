(defproject org.openvoxproject/lein-ezbake "2.8.0-SNAPSHOT"
  :description "A system for building packages for trapperkeeper-based applications"
  :url "https://github.com/openvoxproject/ezbake"
  :license {:name "Apache License 2.0"
            :url "http://www.apache.org/licenses/LICENSE-2.0"}

  :dependencies [[me.raynes/fs "1.4.6" :exclusions [org.clojure/clojure]]
                 [me.raynes/conch "0.8.0"]
                 [clj-time "0.15.2"]
                 [cheshire "6.1.0"]
                 [prismatic/schema "1.4.1"]
                 [org.openvoxproject/typesafe-config "0.2.2" :exclusions [org.clojure/clojure]]]

  :deploy-repositories [["releases" {:url "https://clojars.org/repo"
                                     :username :env/CLOJARS_USERNAME
                                     :password :env/CLOJARS_PASSWORD
                                     :sign-releases false}]]

  :scm {:name "git" :url "https://github.com/openvoxproject/ezbake"}

  :resource-paths ["resources/"]

  :profiles {:dev {:dependencies [[io.aviso/pretty "1.4.4"]]}}

  :eval-in-leiningen true)
