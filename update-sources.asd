#-asdf3.3 (error "Needs ASDFv3.3")

(asdf:defsystem "update-sources"
  :class :package-inferred-system
  :description "Update Nix sources"
  :version "0.1"
  :author "Hraban Luyat"
  :licence "AGPLv3"
  :build-operation "program-op"
  :build-pathname "dist/update-sources"
  :entry-point "update-sources:main"
  :depends-on ("update-sources/main"))
