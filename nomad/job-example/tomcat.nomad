variables {
  // tomcat_download_url = "https://archive.apache.org/dist/tomcat/tomcat-10/v10.0.10/bin/apache-tomcat-10.0.10.tar.gz"
  // https://tomcat.apache.org/tomcat-10.0-doc/appdev/sample/
  // war_download_url = "https://tomcat.apache.org/tomcat-10.0-doc/appdev/sample/sample.war"
}

job "tomcat-10" {
  datacenters = ["dc1"]

  type = "service"

  group "tomcat" {
    count = 3

    scaling {
      enabled = true
      min = 1
      max = 3
    }

    task "tomcat" {
      driver = "raw_exec"
      resources {
        network {
          port "http" {}
          port "stop" {}
        }
        cpu = 500
        memory = 512
      }
      env {
        APP_VERSION = "0.1"
        CATALINA_HOME = "${NOMAD_TASK_DIR}/apache-tomcat-10.0.10"
        CATALINA_OPTS = "-Dport.http=$NOMAD_PORT_http -Dport.stop=$NOMAD_PORT_stop -Ddefault.context=$NOMAD_TASK_DIR -Xms256m -Xmx512m"
        JAVA_HOME = "/usr/lib/jvm/java-11-openjdk-amd64"
      }
      template {
data = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Server port="${port.stop}" shutdown="SHUTDOWN">
    <Listener className="org.apache.catalina.startup.VersionLoggerListener"/>
    <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on"/>
    <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener"/>
    <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener"/>
    <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener"/>
    <GlobalNamingResources>
        <Resource name="UserDatabase" auth="Container" type="org.apache.catalina.UserDatabase" description="User database that can be updated and saved" factory="org.apache.catalina.users.MemoryUserDatabaseFactory" pathname="conf/tomcat-users.xml"/>
    </GlobalNamingResources>
    <Service name="Catalina">
        <Connector port="${port.http}" protocol="HTTP/1.1" connectionTimeout="20000"/>
        <Engine name="Catalina" defaultHost="localhost">
            <Realm className="org.apache.catalina.realm.LockOutRealm">
                <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase"/>
            </Realm>
            <Host name="localhost" appBase="${default.context}/webapps/" unpackWARs="true" autoDeploy="true">
                <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" prefix="localhost_access_log" suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b"/>
            </Host>
        </Engine>
    </Service>
</Server>
EOF
        destination = "local/conf/server.xml"
      }
      artifact {
        source = "{{ key \"backend/info/tomcat\" }}"
        destination = "/local"
      }
      artifact {
        source = "{{ key \"backend/info/war\" }}"
        destination = "/local/webapps"
      }
      config {
        command = "${CATALINA_HOME}/bin/catalina.sh"
        args = ["run", "-config", "$NOMAD_TASK_DIR/conf/server.xml"]
      }
      service {
        name = "legacy-tomcat"
        tags = ["tomcat"]

        port = "http"

        check {
          type  = "tcp"
          interval = "10s"
          timeout  = "2s"
          port  = "http"
        }
      }
    }
  }
}
