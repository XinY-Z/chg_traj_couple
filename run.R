source('config.R')
source('utils.R')


file_path <- readline('Put the directory of the data here: ')

dt <- fread(file_path)

changepoints <- map(dt, 'changepoint')
r2 <- map(dt, 'r2')
similarities <- map(dt, 'similarity')

print(changepoints)
print(r2)
print(similarities)
