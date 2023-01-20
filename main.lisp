;; Copyright © 2022, 2023  Hraban Luyat
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
  (:import-from #:cl-ppcre)
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

(defun read-sha (url rev)
  ;; MFW I think I’m galaxy brain scripting but I’m blub. Is this the inverse of
  ;; xkcd 224?
  (cl-ppcre:register-groups-bind (user repo) ("^https://github\\.com/([^/]+)/([^/]+?)\\.git" url)
    (sh:run/ss `(sh:pipe
                 (nix run "nixpkgs#nix-prefetch-github" -- ,user ,repo --rev ,rev)
                 (jq -r ".sha256")))))

(defun process (system old url)
  ;; Only works with hashes for now. Actual versions would need better
  ;; heuristics: fetch all tags, see if there’s an update?
  (when (hashp old)
    (let ((head (read-head url)))
      (unless (equal head old)
        (let ((row (append (list system old head)
                           (some-> (read-sha url head) list))))
          (format T "~A~%" (str:join #\Tab row)))))))

(defun main-aux (fname)
  (dolist (line (parse fname))
    (apply #'process (str:split #\Tab line))))

(defun main ()
  (apply #'main-aux (uiop:command-line-arguments)))
