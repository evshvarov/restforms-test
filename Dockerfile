ARG IMAGE=intersystems/iris:2019.1.0S.111.0
ARG IMAGE=store/intersystems/irishealth:2019.3.0.308.0-community
ARG IMAGE=store/intersystems/iris-community:2019.3.0.309.0
ARG IMAGE=store/intersystems/iris-community:2019.4.0.379.0
ARG IMAGE=store/intersystems/iris-community:2020.1.0.197.0
ARG IMAGE=intersystemsdc/iris-community:2020.1.0.209.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.2.0.196.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.1.0.215.0-zpm
FROM $IMAGE

USER root

WORKDIR /opt/irisapp
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisapp
COPY irissession.sh /
RUN chmod +x /irissession.sh 

USER irisowner

COPY  Installer.cls .
COPY  src src
SHELL ["/irissession.sh"]

RUN \
  do $SYSTEM.OBJ.Load("Installer.cls", "ck",,1) \
  set sc = ##class(App.Installer).setup() \
  # if sc<1 write $SYSTEM.OBJ.DisplayError(sc) \
  zn "IRISAPP" \
  zpm "install restforms2" \
  zpm "install swagger-ui"\
  zpm "install restforms2-ui" \
  #; do manual source load and compile 
  do ##class(Form.Util.Init).populateTestForms() \
  zn "%SYS" \
  write "Modify forms application security...",! \
  set webName = "/forms" \
  set webProperties("AutheEnabled") = 32 \
  set webProperties("MatchRoles")=":%DB_%DEFAULT" \
  set sc = ##class(Security.Applications).Modify(webName, .webProperties) \
  # if sc<1 write $SYSTEM.OBJ.DisplayError(sc) \
  write "Add Role for CSPSystem User...",! \
  set sc=##class(Security.Users).AddRoles("CSPSystem","%DB_%DEFAULT") \
  if sc<1 write $SYSTEM.OBJ.DisplayError(sc) \
 # bringing the standard shell back
SHELL ["/bin/bash", "-c"]
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]