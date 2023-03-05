default: send rec

#tlsrec: tlsrec.o

#tlsrec.o:
	@#@gcc -o tlsrec tlsrec.c -lcrypto -lssl

send: send.o

rec: rec.o

send.o:

rec.o:

clean:
	@rm -f send.o send rec.o rec
	@echo Done!
