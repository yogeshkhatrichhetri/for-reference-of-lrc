function h=p4_hash(file)
f=fopen(file,'rb'); assert(f>=0,'Cannot read %s',file); c=onCleanup(@()fclose(f));
b=fread(f,Inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256');
md.update(typecast(b,'int8')); v=typecast(md.digest(),'uint8');
h=lower(reshape(dec2hex(v,2).',1,[]));
end
