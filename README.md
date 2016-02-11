CADRACSwippableCell
====================

Swippable UICollectionViewCell subclass made with Reactive Cocoa.


<p align="center"><img src="https://raw.githubusercontent.com/TopicSo/CADRACSwippableCell/master/Screenshots/swipepreview.gif"/></p>


##Usage

To use it, your collection cell should subclass `CADRACSwippableCell` and you should provide a `revealView` to be shown beneath the cell and for the cell to be swippable. 

After that, you can subscribe to `revealViewSignal` to get `:next` events when the reveal view is hidden/shown. You can also provide the allowed swipe direction with `allowedDirection`.

```objc
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CustomCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ReuseIdentifier" forIndexPath:indexPath];
    
    UIView *bottomView = [[UIView alloc] init];
    bottomView.frame = (CGRect){
        .size = CGSizeMake(CGRectGetWidth(collectionView.bounds)/2, CGRectGetHeight(cell.bounds))
    };
    
    cell.allowedDirection = arc4random_uniform(2);
    cell.revealView = bottomView;
    [[cell.revealViewSignal filter:^BOOL(NSNumber *isRevealed) {
        return [isRevealed boolValue];
    }] subscribeNext:^(id x) {
        [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(CustomCollectionCell *otherCell, NSUInteger idx, BOOL *stop) {
            if (otherCell != cell)
            {
                [otherCell hideRevealViewAnimated:YES];
            }
        }];
    }];
    
    bottomView.backgroundColor = cell.allowedDirection == CADRACSwippableCellAllowedDirectionRight ? [UIColor redColor] : [UIColor blueColor];
    
    return cell;
}
```

Refer to the header file [`CADRACSwippableCell.h`](Source/CADRACSwippableCell.h) for more documentation.

###Install
We strongly encourage you to use CocoaPods. It's simple, just add the dependency to your `Podfile`:

```ruby
platform :ios, '7.0'

pod 'CADRACSwippableCell'
```

And then running `pod install` will install the dependencies.

Finally, import the header file wherever you want to use it:

```objc
#import "CADRACSwippableCell.h"
```

And you are done!


### Demo

To check the demo, first install the dependencies with CocoaPods. After that, build and run the `Example` project in Xcode.


## MIT License
Copyright (c) 2014 [Joan Romano](http://twitter.com/joanromano)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
