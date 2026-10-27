function p4_json(file,value)
assert(~isfile(file),'Refusing to overwrite %s',file);
f=fopen(file,'w'); assert(f>=0,'Cannot create %s',file); c=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(value,PrettyPrint=true));
end
