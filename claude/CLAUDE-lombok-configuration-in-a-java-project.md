# lombok configuration in a Java project

In a Java project (with a pom.xml, or a gradle build), respect the lombok.config file. In most of the cases, it will
have:

```
lombok.accessors.chain=true
lombok.equalsAndHashCode.callSuper=call

# Section 7.2 of Checker Framework manual
lombok.addLombokGeneratedAnnotation = true

# Best practice
lombok.addNullAnnotations=checkerframework

lombok.log.fieldName=logger
```

Respect the name for the logger. Also, in a inheritance of classes or a class implementing an interface, prefer the most
specific logger in the subclass (respect the more specific lombok annotation of @Slf4j).
