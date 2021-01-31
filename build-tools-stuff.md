# build tools stuff
`config.log` -> super important !
	* first error that is not benign, not the last error

### docs:
	* shared questions: [Google Docs - create and edit documents online, for free.](https://docs.google.com/document/d/1Dyshsq-A8mXeMz5-CQ-o837mttOIGypRZo0gWrgdyT0/edit)
	* hella resources: [Build Systems for Core Course - Google Docs](https://docs.google.com/document/d/1PM3l7BSx5qZEJlf7GjmapKZTGLenPGn5A5YKNTWOhQs/edit)
	* notes from our convo: [build system notes 1.5.21 - Google Docs](https://docs.google.com/document/d/1Rj3tmhIsI-3LSWjrrT673J2-NxIv3PL1QLgmLd9d0kY/edit)


### depends:
	* in c/c++ projects, there's no native package managers. Every project re-invents. The depends folder is our attempt.
	* want an isolated, controlled way to build our dependancies in a safe, reproducible way.
	* everything in depends can be switched out for things in your system, eg. You could use boost on your system instead of the boost in the depends
	* defines a canonical way to build the dependencies
	* instructions are super simple: just run make
	* after it makes all the dependancies, it makes a file. Example file is `config.site.in`  (glue between depends and configure)
	* to use depends, needs to configure with the `config_site` variable set (default behavior of autoconf), or prefix

### CI compilation failure on something:
	* our CI all runs in docker, so you should be able to recreate directly
	* startup docker container, build depends, configure, compile
	* docker files: [core-review/docker at master · fanquake/core-review · GitHub](https://github.com/fanquake/core-review/tree/master/docker)
	* build, run, ssh, go into depends..

### Resolved questions:
**question: what boost am I using?**

Can use `otool -L src/bitcoind` to discover the library paths