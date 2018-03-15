module Git
  # Lib class from https://github.com/voxpupuli/modulesync/pull/144/files
  #
  # Copyright [2018] [Dave Wongillies https://github.com/davewongillies]

  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at

  #     http://www.apache.org/licenses/LICENSE-2.0

  # Unless required by applicable law or agreed to in writing, software
  # distributed under the License is distributed on an "AS IS" BASIS,
  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  # See the License for the specific language governing permissions and
  # limitations under the License.
   class Lib
    # Monkey patch ls_files until https://github.com/ruby-git/ruby-git/pull/320 is resolved
    def ls_files(location=nil)
      location ||= '.'
      hsh = {}
      command_lines('ls-files', ['--stage', location]).each do |line|
        (info, file) = line.split("\t")
        (mode, sha, stage) = info.split
        file = eval(file) if file =~ /^\".*\"$/ # This takes care of quoted strings returned from git
        hsh[file] = {:path => file, :mode_index => mode, :sha_index => sha, :stage => stage}
      end
      hsh
    end
  end
end
