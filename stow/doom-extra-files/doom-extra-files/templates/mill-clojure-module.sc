// mill-clojure-module.sc - Mill module for Clojure support
// Save this file in your project or as a common library

import mill._, scalalib._, java._

/**
 * A Mill module trait for Clojure projects.
 * This trait extends JavaModule to provide Clojure-specific functionality.
 */
trait ClojureModule extends JavaModule {
  /** The Clojure version to use */
  def clojureVersion = "1.12.0"
  
  /** Additional Clojure dependencies */
  def clojureDeps = Agg(
    ivy"org.clojure:clojure:${clojureVersion}",
    ivy"org.clojure:tools.namespace:1.5.0"
  )
  
  /** Add Clojure dependencies to the module */
  override def ivyDeps = super.ivyDeps() ++ clojureDeps
  
  /** Define source directories for Clojure files */
  def clojureSourceDirectories = T.sources(millSourcePath / "src" / "clojure")
  
  /** Include Clojure source files in the module's sources */
  override def allSourceFiles = T{
    super.allSourceFiles() ++ clojureSourceDirectories().flatMap(p => 
      os.walk(p.path).filter(_.last.endsWith(".clj") || _.last.endsWith(".cljc"))
    )
  }
  
  /** Compile Clojure sources using AOT compilation if needed */
  def compileClojure = T{
    val dest = T.dest
    val cp = compileClasspath().map(_.path)
    
    // First copy the source files to the destination
    clojureSourceDirectories().foreach { src =>
      os.walk(src.path)
        .filter(path => path.last.endsWith(".clj") || path.last.endsWith(".cljc"))
        .foreach { file =>
          val relPath = file.relativeTo(src.path)
          val destPath = dest / relPath
          os.copy(file, destPath, createFolders = true)
      }
    }
    
    // Optional: Perform AOT compilation for namespaces marked with :gen-class
    // This is a simplified example; a real implementation would parse namespace
    // declarations to find those with :gen-class
    
    PathRef(dest)
  }
  
  /** Override compile to include Clojure files */
  override def compile = T{
    // First compile Java sources (if any)
    val javaOutput = super.compile()
    
    // Then compile Clojure sources
    val clojureOutput = compileClojure()
    
    // For simplicity, we'll just return the Java output
    // A more complete implementation would merge the outputs
    javaOutput
  }
  
  /** Add task for running a Clojure REPL */
  def repl = T.command{
    val cp = runClasspath().map(_.path)
    os.proc("java", "-cp", cp.mkString(":"), "clojure.main")
      .call(stdin = os.Inherit, stdout = os.Inherit)
  }
  
  /** Add task for starting a nREPL server that CIDER can connect to */
  def nrepl = T.command{
    val cp = runClasspath().map(_.path)
    // This requires nREPL to be in your dependencies
    os.proc("java", "-cp", cp.mkString(":"), "clojure.main", "-e",
      """
      (do
        (require '[nrepl.server :as nrepl])
        (println "Starting nREPL server on port 7888...")
        (def server (nrepl/start-server :port 7888))
        (println "nREPL server started, ready for connections.")
        (spit ".nrepl-port" 7888)
        (.addShutdownHook (Runtime/getRuntime)
          (Thread. (fn [] (println "Stopping nREPL server...") (nrepl/stop-server server))))
        @(promise))
      """)
      .call(stdin = os.Inherit, stdout = os.Inherit)
  }
  
  /** Add task for running Clojure tests */
  def clojureTest = T.command{
    val cp = runClasspath().map(_.path)
    // This is a simple example using clojure.test
    os.proc("java", "-cp", cp.mkString(":"), "clojure.main", "-e",
      """
      (do
        (require '[clojure.test :as test])
        (def test-namespaces 
          (->> (all-ns)
               (filter #(and (re-find #"-test$|test-" (name (ns-name %)))
                             (the-ns %)))))
        (if (seq test-namespaces)
          (do
            (println "Running tests in" (count test-namespaces) "namespaces")
            (apply test/run-tests test-namespaces))
          (println "No test namespaces found")))
      """)
      .call(stdin = os.Inherit, stdout = os.Inherit)
  }
  
  /** Add task for running a Clojure main namespace */
  def runClojure(mainNs: String) = T.command{
    val cp = runClasspath().map(_.path)
    os.proc("java", "-cp", cp.mkString(":"), "clojure.main", "-m", mainNs)
      .call(stdin = os.Inherit, stdout = os.Inherit)
  }
}

// Example usage:
/*
object myproject extends ClojureModule {
  // Project-specific settings
  override def clojureVersion = "1.11.1"
  
  // Additional dependencies beyond Clojure core
  override def ivyDeps = super.ivyDeps() ++ Agg(
    ivy"org.clojure:core.async:1.6.673",
    ivy"org.clojure:tools.nrepl:0.2.13", // For CIDER integration
    ivy"compojure:compojure:1.7.0"
  )
  
  // Example: Override source directories for a different project structure
  // override def clojureSourceDirectories = T.sources(millSourcePath / "clj")
}
*/
