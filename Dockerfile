FROM swiftdevel/swift

ENV APP_NAME=Quark

WORKDIR /$APP_NAME/

ADD ./Package.swift /$APP_NAME/
ADD ./Sources /$APP_NAME/Sources
ADD ./Configuration /$APP_NAME/Configuration

RUN swift build -c release

EXPOSE 8080

CMD .build/release/ExampleApplication
