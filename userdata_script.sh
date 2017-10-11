#!/bin/bash

JENKINS_USER=jenkins
ADMIN_USER=admin
JENKINS_HOME_FOLDER=/Users/$JENKINS_USER
ADMIN_HOME_FOLDER=/Users/$ADMIN_USER

if  [ $UID -ne 0 ];
then echo "Please run $0 as root."
exit 1
fi

source $ADMIN_HOME_FOLDER/.bash_profile

echo "Copying admin .bash_profile to jenkins user folder"
cp $ADMIN_HOME_FOLDER/.bash_profile $JENKINS_HOME_FOLDER/.bash_profile

CURRENT_DIR=`pwd`
cd /
echo "jenkins ALL = NOPASSWD: ALL" >> /etc/sudoers
echo "admin ALL = NOPASSWD: ALL" >> /etc/sudoers

echo "Installing command line tools"
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
PROD=$(softwareupdate -l |
  grep "\*.*Command Line" |
  head -n 1 | awk -F"*" '{print $2}' |
  sed -e 's/^ *//' |
  tr -d '\n')
softwareupdate -i "$PROD" --verbose;


echo "Installing homebrew and xcode command line tools"
rm -rf /usr/local/*
rm -rf /Library/Developer/CommandLineTools
su admin -c 'source /Users/admin/.bash_profile && yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
chown -R $JENKINS_USER /usr/local/
cd /
su admin -c 'sudo chown -R $(whoami):admin /usr/local && sudo chmod -R g+rwx /usr/local'
su admin -c 'brew update && brew doctor'
su admin -c 'brew cask install Caskroom/cask/java'

echo "Disabling osxkeychain for git"
echo "[helper]" > /Applications/Xcode.app/Contents/Developer/usr/share/git-core/gitconfig

echo "Installing RVM"
cd /
su jenkins -c "sudo chown -R jenkins:admin /usr/local"
su -l jenkins -c "source /Users/jenkins/.bash_profile && curl -sSL https://get.rvm.io | bash -s 1.29.1"


echo "Installing ruby 2.4.0"
su jenkins -c "source /Users/jenkins/.profile && rvm install ruby-2.4.0 && gem install bundler"

echo "Setting up github keys"
cd /
su -l jenkins -c " sudo rm -rf /Users/jenkins/.ssh && mkdir /Users/jenkins/.ssh"
cp /Users/admin/Desktop/mac_jenkins_ci_slaves/githubkey /Users/jenkins/.ssh
chmod 600 /Users/jenkins/.ssh/githubkey && chown jenkins /Users/jenkins/.ssh/githubkey
su jenkins -c 'eval "$(ssh-agent -s)" && ssh-add /Users/jenkins/.ssh/githubkey && ssh -o StrictHostKeyChecking=no -l jenkins github.deere.com'
su jenkins -c 'networksetup -setairportpower airport off'

echo "Cleaning up sudoers file"
sed -i '' '/admin ALL = NOPASSWD: ALL/d' /etc/sudoers
sed -i '' '/jenkins ALL = NOPASSWD:ALL/d' /etc/sudoers

echo 'eval $(ssh-agent -s)' >> "${JENKINS_HOME_FOLDER}/.bash_profile"
echo "ssh-add ~/.ssh/githubkey" >> "${JENKINS_HOME_FOLDER}/.bash_profile"
echo "source /Users/jenkins/.profile" >> "${JENKINS_HOME_FOLDER}/.bash_profile"


