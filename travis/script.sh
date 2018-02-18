#!/bin/bash

RETSTATUS=0
STATUS=0

# If top-level build file, run that
if [ -e "$MODULE_ROOT/build.sh" ]; then
	./build.sh
else
	# If iOS module exists, build
	if [ -d "$MODULE_ROOT/ios/" ]; then

		echo
		echo "Building iOS version"
		echo

		cd $MODULE_ROOT/ios/
		cp $MODULE_ROOT/titanium.xcconfig titanium.xcconfig
		cat titanium.xcconfig
	  	ti build -p ios --build-only

		let STATUS=$?
		if (( "$RETSTATUS" == "0" )) && (( "$STATUS" != "0" )); then
		  	let RETSTATUS=$STATUS
		else
			# Test Module in a Titanium Application
			echo "Reading module manifest"
			MODULE_ID=$(sed -n 's/.*moduleid: \([^ ]*\).*/\1/p' manifest)
			MODULE_VERSION=$(sed -n 's/^version: \([^ ]*\).*/\1/p' manifest)
			echo "Module Info: " $MODULE_ID '@' $MODULE_VERSION

			# Install module
			echo "Installing module"
			ti sdk install $MODULE_ID* -q

			# Create new application
			echo "Creating new application"
			ti create -t app -p ios -d "./TestModule" -n "TestModule" --id "com.appc.TestModule" -u "http://appcelerator.com" --force -q
			cd ./TestModule/TestModule

			# Append module to manifest
			echo "Add module to application"
			sed -i "" 's/<modules>/&<module version="'$MODULE_VERSION'">'$MODULE_ID'<\/module>/g' tiapp.xml

			# Configure app.js
			MODULE_EXAMPLE=$HOME/Library/Application\ Support/Titanium/modules/iphone/$MODULE_ID/$MODULE_VERSION/example/
			if [ -e "$MODULE_EXAMPLE/app.js" ]; then
				echo "Copying module example"
				cp -r "$MODULE_EXAMPLE." ./Resources/
			else
				#Append module to app.js
				echo "Appending module require to app.js"
				cd ./Resources/
				echo -e "var moduleToTest = require('"$MODULE_ID"');\n$(cat app.js)" > app.js
				cd ../
			fi

			#Build application but do not run simulator
			echo "Build application"
			ti build -b -p ios -d "./" —log-level info

			let STATUS=$?

			if (( "$RETSTATUS" == "0" )) && (( "$STATUS" != "0" )); then
				let RETSTATUS=$STATUS
			fi
		fi
	fi

	# If Android module exists, build
	if [ -d "$MODULE_ROOT/android/" ]; then

	  echo
	  echo "Building Android version"
	  echo

	  cd $MODULE_ROOT/android/
	  cp $MODULE_ROOT/build.properties build.properties
	  cat build.properties

	  # if lib folder doesn't exist, create it
	  mkdir -p lib
	  # if build folder doesn't exist, create it
	  mkdir -p build
	  # if build/docs folder doesn't exist, create it
	  mkdir -p build/docs

	  ti build -p android --build-only

	  let STATUS=$?
	  if (( "$RETSTATUS" == "0" )) && (( "$STATUS" != "0" )); then
	    let RETSTATUS=$STATUS
	  fi

	  cd $MODULE_ROOT
	fi
fi

exit $RETSTATUS
