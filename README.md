rdap
====

retarded directory access protocol

My fun time project for trying to implement LDAP Protocol. So far, it accepts connections, able to parse LDAP Messages ( see RFC4511 ) partially, doesn't have most of the implementation. Only low-level protocol is handled (not completely). 

I might make this something into `LDAP Binary Interface` <-> `JSON HTTP Interface` proxy maybe.

`Objective-C` is chosen for being handy. I plan to make it work with GNUStep, maybe will convert to plain C if it's worth it.
