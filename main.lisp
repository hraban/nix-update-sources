;; Copyright © 2022  Hraban Luyat
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published
;; by the Free Software Foundation, version 3 of the License.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

(uiop:define-package #:update-sources
  (:nicknames #:update-sources/main)
  (:use #:cl #:arrow-macros)
  (:local-nicknames (#:sh #:inferior-shell))
  (:import-from #:str)
  (:export #:main))

(in-package #:update-sources/main)

(defun parse (fname)
  (sh:run `(jq -r "to_entries | .[]  | \"\\(.key)\\t\\(.value.rev)\\t\\(.value.gitRepoUrl)\"")
          :input fname
          :output :lines))

;; TODO: Use this when comparing tags
(defun version-< (v1 v2)
  "Compare v1 < v2 according to semver"
  ;; 🤷 this works.
  (let ((nix (format NIL "(import <nixpkgs> {}).lib.strings.versionOlder \"~A\" \"~A\"" v1 v2)))
    (-> (sh:run/ss `(nix-instantiate --read-write-mode --strict --eval "-E" ,nix))
        (equal "true"))))

(defun hashp (rev)
  (-> rev length (= 40)))

(defun read-head (url)
  (->> `(git ls-remote ,url "HEAD")
       sh:run/ss
       (str:split #\Tab)
       first))

(defun main-aux (fname)
  (dolist (line (parse fname))
    (destructuring-bind (system old url) (str:split #\Tab line)
      ;; Only works with hashes for now. Actual versions would need better
      ;; heuristics: fetch all tags, see if there’s an update?
      (when (hashp old)
        (let ((head (read-head url)))
          (unless (equal head old)
            (format T "~A: ~A -> ~A~%" system old head)))))))

(defun main ()
  (apply #'main-aux (uiop:command-line-arguments)))
