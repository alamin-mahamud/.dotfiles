echo
echo "Setup ssh key for britecore"
EMAIL=alamin.mahamud@britecore.com
KEY_FILE=britecore_rsa
# generate ssh key
chmod 600 ~/.ssh/britecore_rsa
chmod 644 ~/.ssh/britecore_rsa.pub

echo
echo "Configure .aws"
aws configure


bc-pem -c


echo
echo "[Powertools]"
pip install -U git+ssh://git@github-bc.com/IntuitiveWebSolutions/PowerTools.git


echo
echo "[Teleport]"
brew install teleport --build-from-source
tsh --proxy=unicorn.britecorepro.com login
