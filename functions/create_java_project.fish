function create_java_project
    # -------------------------------------------------------------------------
    # create_java_project (fish shell function)
    #
    # Description:
    #   Automates the creation of a new Java project structure.
    #   It sets up directories, boilerplate files, optional helper files, and a Git repo.
    #
    # Usage:
    #   create_java_project [target_dir] project_name
    #
    # Arguments:
    #   target_dir   (optional) Path where the project folder will be created.
    #                Defaults to the current directory.
    #
    #   project_name (required) Name of the project, also used as the
    #                top-level package name inside src/.
    #
    # Example:
    #   create_java_project MyApp
    #   create_java_project ~/Projects CoolApp
    # -------------------------------------------------------------------------

    set -l target_dir
    set -l outer_project_name

    # Check arguments
    if test (count $argv) -eq 1
        set outer_project_name $argv[1]
        set target_dir .
    else if test (count $argv) -eq 2
        set target_dir $argv[1]
        set outer_project_name $argv[2]
    else
        echo "Usage: create_java_project [target_dir] project_name"
        return 1
    end

    set inner_project_name (string lower $outer_project_name)
    set -l abs_target_dir (realpath $target_dir)
    set -l proj_dir $abs_target_dir/$outer_project_name

    echo "Creating Java project '$outer_project_name' in '$proj_dir' ..."

    # -------------------------
    # Create directory structure
    # -------------------------
    mkdir -p $proj_dir/src/main/java/$inner_project_name
    mkdir -p $proj_dir/src/main/resources/logging
    mkdir -p $proj_dir/src/test/java/$inner_project_name
    mkdir -p $proj_dir/docs
    mkdir -p $proj_dir/lib
    mkdir -p $proj_dir/.github/workflows
    mkdir -p $proj_dir/gradle/wrapper

    # -------------------------
    # Create optional standard files
    # -------------------------
    touch $proj_dir/.gitignore
    touch $proj_dir/README.md
    touch $proj_dir/LICENSE
    touch $proj_dir/CHANGELOG.md
    touch $proj_dir/CONTRIBUTING.md
    touch $proj_dir/.editorconfig
    touch $proj_dir/gradle.properties

    # -------------------------
    # Gradle build files
    # -------------------------
    # build.gradle
    set build_gradle $proj_dir/build.gradle
    echo "plugins {" > $build_gradle
    echo "    id 'java'" >> $build_gradle
    echo "}" >> $build_gradle
    echo "" >> $build_gradle
    echo "group = 'com.example'" >> $build_gradle
    echo "version = '1.0-SNAPSHOT'" >> $build_gradle
    echo "" >> $build_gradle
    echo "repositories {" >> $build_gradle
    echo "    mavenCentral()" >> $build_gradle
    echo "}" >> $build_gradle
    echo "" >> $build_gradle
    echo "dependencies {" >> $build_gradle
    echo "    testImplementation 'org.junit.jupiter:junit-jupiter:5.9.3'" >> $build_gradle
    echo "}" >> $build_gradle
    echo "" >> $build_gradle
    echo "test {" >> $build_gradle
    echo "    useJUnitPlatform()" >> $build_gradle
    echo "}" >> $build_gradle

    # settings.gradle
    echo "rootProject.name = '$outer_project_name'" > $proj_dir/settings.gradle

    # -------------------------
    # Create Main.java
    # -------------------------
    set main_java_file $proj_dir/src/main/java/$inner_project_name/Main.java
    echo "package $inner_project_name;" > $main_java_file
    echo "public class Main {" >> $main_java_file
    echo "    public static void main(String[] args) {" >> $main_java_file
    echo "        System.out.println(\"Hello, $outer_project_name!\");" >> $main_java_file
    echo "    }" >> $main_java_file
    echo "}" >> $main_java_file

    # -------------------------
    # Create Test class
    # -------------------------
    set test_java_file $proj_dir/src/test/java/$inner_project_name/MainTest.java
    echo "package $inner_project_name;" > $test_java_file
    echo "import org.junit.jupiter.api.Test;" >> $test_java_file
    echo "import static org.junit.jupiter.api.Assertions.*;" >> $test_java_file
    echo "public class MainTest {" >> $test_java_file
    echo "    @Test" >> $test_java_file
    echo "    public void sampleTest() {" >> $test_java_file
    echo "        assertTrue(true);" >> $test_java_file
    echo "    }" >> $test_java_file
    echo "}" >> $test_java_file

    # -------------------------
    # Dockerfile
    # -------------------------
    set docker_file $proj_dir/Dockerfile
    echo "FROM eclipse-temurin:17-jdk-alpine" > $docker_file
    echo "WORKDIR /app" >> $docker_file
    echo "COPY . ." >> $docker_file
    echo "RUN ./gradlew build --no-daemon" >> $docker_file
    echo "CMD [\"java\", \"-cp\", \"build/classes/java/main\", \"$inner_project_name.Main\"]" >> $docker_file

    # -------------------------
    # GitHub Actions workflow
    # -------------------------
    set workflow_file $proj_dir/.github/workflows/java-ci.yml
    echo "name: Java CI" > $workflow_file
    echo "on:" >> $workflow_file
    echo "  push:" >> $workflow_file
    echo "    branches: [ main ]" >> $workflow_file
    echo "  pull_request:" >> $workflow_file
    echo "    branches: [ main ]" >> $workflow_file
    echo "jobs:" >> $workflow_file
    echo "  build:" >> $workflow_file
    echo "    runs-on: ubuntu-latest" >> $workflow_file
    echo "    steps:" >> $workflow_file
    echo "      - uses: actions/checkout@v3" >> $workflow_file
    echo "      - name: Set up JDK" >> $workflow_file
    echo "        uses: actions/setup-java@v3" >> $workflow_file
    echo "        with:" >> $workflow_file
    echo "          distribution: 'temurin'" >> $workflow_file
    echo "          java-version: '17'" >> $workflow_file
    echo "      - name: Build with Gradle" >> $workflow_file
    echo "        run: ./gradlew build" >> $workflow_file

    # -------------------------
    # Gradle Wrapper
    # -------------------------
    cd $proj_dir
    echo "Setting up Gradle wrapper ..."
    gradle wrapper --gradle-version 8.3
    chmod +x gradlew

    # -------------------------
    # Git init
    # -------------------------
    git init

    echo "✅ Java project created successfully!"
    echo "To build: ./gradlew build"
    echo "To run: ./gradlew run or docker build/run"
end
