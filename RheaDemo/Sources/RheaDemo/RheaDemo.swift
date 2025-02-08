// The Swift Programming Language
// https://docs.swift.org/swift-book

import RheaTime

#load {
    print(111)
}

#premain {
    print(222)
}

#appDidFinishLaunching {
    print(333)
}

@main
struct Demo {
    
    #load {
        print(444)
    }

    #premain {
        print(555)
    }
    
    #appDidFinishLaunching {
        print(666)
    }
    
    static func main() {
        
    }
}
