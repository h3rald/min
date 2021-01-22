# use Alpine+Nim as a basis 
FROM frolvlad/alpine-nim

# install necessary packages
RUN apk update
RUN apk add curl git

# clone repository
RUN git clone https://github.com/h3rald/min.git

# install nifty
RUN nimble install -y nifty

# set path to nifty
# (for some reason it doesn't pick it up by itself)
ENV PATH="/root/.nimble/pkgs/nifty-1.2.2:${PATH}"

# install dependencies with nifty
RUN cd min && nifty install

# build min
RUN cd min && nim c -d:release -d:ssl -o:min min

# set our PATH to the min's location
ENV PATH="/min:${PATH}"

# set our workdir to /home
# (where our local files will be mirrored)
WORKDIR /home

# start up the main binary 
ENTRYPOINT [ "/min/min" ]